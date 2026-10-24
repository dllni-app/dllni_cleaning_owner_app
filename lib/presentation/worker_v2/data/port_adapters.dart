import '../contracts/common.dart';
import '../contracts/models.dart';
import '../contracts/ports.dart';
import '../contracts/requests.dart';
import 'runtime_adapter.dart';
import 'transport.dart';
import 'wire_mappers.dart';
import 'work_summary_cache.dart';

/// Fixture-ready composition. S00 supplies the verified session and the
/// authenticated transport implementation in a separate integration gate.
/// No HTTP routes or credentials are embedded in this library.
class WorkerDataAdapters {
  WorkerDataAdapters({
    WorkerReadTransport? reads,
    WorkerWriteTransport? writes,
    WorkSummaryStorage? cacheStorage,
    DateTime Function()? clock,
  }) {
    late WorkerRuntimeAdapter runtime;
    final cache = ScopedWorkSummaryCache(
      storage: cacheStorage ?? MemoryWorkSummaryStorage(),
      currentIdentity: () => runtime.context,
      isAuthenticated: () => runtime.phase == RuntimePhase.signedIn,
      clock: clock,
    );
    runtime = WorkerRuntimeAdapter(cache: cache);
    this.runtime = runtime;
    final exec = _AdapterExecutor(
      runtime,
      reads,
      writes,
      cache,
      clock ?? DateTime.now,
    );
    access = WorkerAccessAdapter._(exec);
    work = WorkerWorkAdapter._(exec);
    mission = WorkerMissionAdapter._(exec);
    finance = WorkerFinanceAdapter._(exec);
    communications = WorkerCommunicationsAdapter._(exec);
  }

  late final WorkerRuntimeAdapter runtime;
  late final AccessAccountPort access;
  late final WorkPort work;
  late final MissionPort mission;
  late final FinancePort finance;
  late final CommunicationsPort communications;
}

class _AdapterExecutor {
  _AdapterExecutor(
    this.runtime,
    this.reads,
    this.writes,
    this.cache,
    this.clock,
  );
  final WorkerRuntimeAdapter runtime;
  final WorkerReadTransport? reads;
  final WorkerWriteTransport? writes;
  final ScopedWorkSummaryCache cache;
  final DateTime Function() clock;
  final _pendingRefetch = <String>{};
  final _pendingRefetchAt = <String, int>{};
  final _readFenceVersions = <String, int>{};
  int _commandSequence = 0;
  int get commandSequence => _commandSequence;

  String _identityKey(WorkerSessionContext ctx, String key) =>
      '${ctx.userId}/${ctx.workerId}/${ctx.generation}:$key';

  String _readFenceKey(
    WorkerSessionContext ctx,
    String name,
    WorkScope? scope,
    String? authoritativeKey,
  ) => _identityKey(
    ctx,
    scope == null
        ? authoritativeKey == null
              ? 'operation:$name'
              : 'record:$authoritativeKey'
        : 'scope:${scope.cacheKey}',
  );

  Future<ReadResult<T>> read<T>(
    String name,
    T Function(Object?) parse, {
    Map<String, Object?> args = const {},
    WorkScope? scope,
    String? authoritativeKey,
    bool Function(T)? matchesRequested,
  }) async {
    final ctx = runtime.context;
    if (ctx == null) {
      return ReadFailure<T>(
        PortFailure(
          kind: FailureKind.unauthenticated,
          reasonCode: 'session_expired',
        ),
      );
    }
    final identityEpoch = runtime.identityEpoch;
    // Only reads begun after an uncertain command can resolve its retry lock.
    final readStartedAt = _commandSequence;
    final scopedRevision = scope == null ? null : cache.revision;
    final fenceKey = _readFenceKey(ctx, name, scope, authoritativeKey);
    final readFence = _readFenceVersions[fenceKey] ?? 0;
    if (reads == null) return ReadFailure<T>(unavailableFailure());
    if (runtime.connection == ConnectionState.offline) {
      return ReadFailure<T>(
        PortFailure(kind: FailureKind.network, reasonCode: 'offline'),
      );
    }
    try {
      final result = await reads!.read(
        WorkerWireRequest(operation: name, context: ctx, arguments: args),
      );
      if (!isCurrentSession(ctx, identityEpoch)) return expiredRead<T>();
      if (result.status < 200 || result.status >= 300) {
        if (result.status == 401) await runtime.purgeSessionData();
        if (result.status == 403) {
          _readFenceVersions[fenceKey] =
              (_readFenceVersions[fenceKey] ?? 0) + 1;
          if (name == 'agenda') {
            await cache.purgeAll();
          } else if (scope != null) {
            await cache.purgeScope(scope);
          }
        }
        if (result.status != 401 && !isCurrentSession(ctx, identityEpoch)) {
          return expiredRead<T>();
        }
        return ReadFailure<T>(statusFailure(result.status));
      }
      final mapped = parse(result.body);
      if (matchesRequested != null && !matchesRequested(mapped)) {
        return ReadFailure<T>(wireFailure());
      }
      if (!isCurrentSession(ctx, identityEpoch)) return expiredRead<T>();
      if ((_readFenceVersions[fenceKey] ?? 0) != readFence) {
        return ReadFailure<T>(
          PortFailure(kind: FailureKind.forbidden, reasonCode: 'scope_changed'),
        );
      }
      if (scopedRevision != null && cache.revision != scopedRevision) {
        return ReadFailure<T>(
          PortFailure(kind: FailureKind.forbidden, reasonCode: 'scope_changed'),
        );
      }
      if (authoritativeKey != null) {
        final key = _identityKey(ctx, authoritativeKey);
        final pendingAt = _pendingRefetchAt[key];
        if (pendingAt != null && readStartedAt >= pendingAt) {
          _pendingRefetch.remove(key);
          _pendingRefetchAt.remove(key);
        }
      }
      return ReadSuccess<T>(
        value: mapped,
        fetchedAt: clock().toUtc(),
        freshness: ReadFreshness.fresh,
      );
    } on WorkerTransportFault catch (failure) {
      if (!isCurrentSession(ctx, identityEpoch)) return expiredRead<T>();
      return ReadFailure<T>(faultFailure(failure));
    } catch (_) {
      if (!isCurrentSession(ctx, identityEpoch)) return expiredRead<T>();
      return ReadFailure<T>(wireFailure());
    }
  }

  static ReadFailure<T> expiredRead<T>() => ReadFailure<T>(
    PortFailure(
      kind: FailureKind.unauthenticated,
      reasonCode: 'session_expired',
    ),
  );

  bool isCurrentSession(WorkerSessionContext ctx, int epoch) {
    if (epoch != runtime.identityEpoch) return false;
    final current = runtime.context;
    return current != null &&
        current.userId == ctx.userId &&
        current.workerId == ctx.workerId &&
        current.generation == ctx.generation;
  }

  static bool sameSelectedScope(WorkScope requested, WorkScope returned) =>
      requested.bookingId == returned.bookingId &&
      requested.sessionId == returned.sessionId &&
      requested.assignmentId == returned.assignmentId;

  static String scopeKey(WorkScope scope) => 'scope:${scope.cacheKey}';
  static String scopeDomainKey(WorkScope scope, String domain) =>
      '${scopeKey(scope)}:$domain';
  static String entityKey(String entity) => 'entity:$entity';

  Future<CommandResult> command(
    String name, {
    required Map<String, Object?> args,
    required String refetchKey,
    WorkScope? scope,
    String? entity,
  }) async {
    final ctx = runtime.context;
    if (ctx == null) {
      return CommandResult(
        status: CommandStatus.rejected,
        reasonCode: 'session_expired',
        scope: scope,
      );
    }
    final identityEpoch = runtime.identityEpoch;
    final scopedPendingKey = _identityKey(ctx, refetchKey);
    if (_pendingRefetch.contains(scopedPendingKey)) {
      return CommandResult(
        status: CommandStatus.rejected,
        reasonCode: 'refetch_required',
        scope: scope,
      );
    }
    if (writes == null) {
      return CommandResult(
        status: CommandStatus.rejected,
        reasonCode: 'unavailable',
        scope: scope,
      );
    }
    if (runtime.connection != ConnectionState.online) {
      return CommandResult(
        status: CommandStatus.rejected,
        reasonCode: 'offline',
        scope: scope,
      );
    }
    try {
      final result = await writes!.write(
        WorkerWireRequest(operation: name, context: ctx, arguments: args),
      );
      if (!isCurrentSession(ctx, identityEpoch)) {
        return CommandResult(
          status: CommandStatus.rejected,
          reasonCode: 'session_expired',
          scope: scope,
        );
      }
      if (result.status == 401) {
        await runtime.purgeSessionData();
        _pendingRefetch.clear();
        _pendingRefetchAt.clear();
        return CommandResult(
          status: CommandStatus.rejected,
          reasonCode: 'session_expired',
          scope: scope,
        );
      }
      if (result.status == 403 && scope != null) await cache.purgeScope(scope);
      if (result.status == 409) _lockForRefetch(scopedPendingKey);
      if (result.status >= 200 && result.status < 300) {
        // Invalidation is a prompt to refetch authoritative state, never a
        // replacement for it. Each command invalidates its actual domain.
        final topic = switch (name) {
          'save_profile' ||
          'set_account_active' ||
          'save_work_areas' ||
          'save_working_hours' ||
          'save_start_location' => InvalidationTopic.profile,
          'offer_decision' => InvalidationTopic.agenda,
          'post_dispute_message' => InvalidationTopic.dispute,
          'mark_notification_read' ||
          'delete_notification' ||
          'delete_all_notifications' => InvalidationTopic.notifications,
          'send_sos' => InvalidationTopic.booking,
          _ when name.startsWith('mission_') => InvalidationTopic.booking,
          _ => InvalidationTopic.profile,
        };
        runtime.invalidate(topic, scope: scope, entityKey: entity);
        return CommandResult(
          status: CommandStatus.confirmed,
          scope: scope,
          entityKey: entity,
        );
      }
      final failure = statusFailure(result.status);
      return CommandResult(
        status: CommandStatus.rejected,
        reasonCode: failure.reasonCode,
        fieldErrors: result.status == 422
            ? _safeFieldErrors(result.body)
            : const {},
        scope: scope,
      );
    } on WorkerTransportFault catch (failure) {
      if (!isCurrentSession(ctx, identityEpoch)) {
        return CommandResult(
          status: CommandStatus.rejected,
          reasonCode: 'session_expired',
          scope: scope,
        );
      }
      if (failure.kind == WorkerTransportFaultKind.timeout ||
          failure.kind == WorkerTransportFaultKind.unreachable) {
        _lockForRefetch(scopedPendingKey);
        return CommandResult(
          status: CommandStatus.outcomeUnknown,
          scope: scope,
          entityKey: entity,
        );
      }
      return CommandResult(
        status: CommandStatus.rejected,
        reasonCode: 'offline',
        scope: scope,
      );
    } catch (_) {
      if (!isCurrentSession(ctx, identityEpoch)) {
        return CommandResult(
          status: CommandStatus.rejected,
          reasonCode: 'session_expired',
          scope: scope,
        );
      }
      // The write might already have reached the server. Never replay it.
      _lockForRefetch(scopedPendingKey);
      return CommandResult(
        status: CommandStatus.outcomeUnknown,
        scope: scope,
        entityKey: entity,
      );
    }
  }

  void _lockForRefetch(String key) {
    _pendingRefetch.add(key);
    _pendingRefetchAt[key] = ++_commandSequence;
  }

  int? pendingRefetchSequence(WorkerSessionContext ctx, String key) =>
      _pendingRefetchAt[_identityKey(ctx, key)];

  void resolveRefetchAfterCompleteRead(
    WorkerSessionContext ctx,
    String key, {
    required int expectedPendingSequence,
    required int expectedReadSequence,
    required int readStartedAt,
  }) {
    final pendingKey = _identityKey(ctx, key);
    if (!isCurrentSession(ctx, runtime.identityEpoch) ||
        _commandSequence != expectedReadSequence ||
        readStartedAt < expectedPendingSequence ||
        _pendingRefetchAt[pendingKey] != expectedPendingSequence) {
      return;
    }
    _pendingRefetch.remove(pendingKey);
    _pendingRefetchAt.remove(pendingKey);
  }

  Map<String, List<String>> _safeFieldErrors(Object? body) {
    try {
      final errors = WorkerWireMappers.object(
        WorkerWireMappers.object(body)['errors'],
      );
      const allowedFields = {
        'message',
        'reason',
        'phone',
        'password',
        'status',
        'date',
        'sessions',
      };
      return {
        for (final field in errors.keys)
          if (allowedFields.contains(field)) field: const ['invalid'],
      };
    } catch (_) {
      return const {};
    }
  }
}

class WorkerAccessAdapter implements AccessAccountPort {
  WorkerAccessAdapter._(this._exec);
  final _AdapterExecutor _exec;

  @override
  Future<ReadResult<WorkerSessionContext?>> restoreSession() async {
    // S00 alone verifies/restores the existing auth system. The runtime is
    // filled only after that verification; this method never creates identity.
    final current = _exec.runtime.context;
    return ReadSuccess<WorkerSessionContext?>(
      value: current,
      fetchedAt: _exec.clock().toUtc(),
      freshness: ReadFreshness.fresh,
    );
  }

  @override
  Future<ReadResult<WorkerSessionContext>> signIn({
    required String phone,
    required String password,
  }) async => ReadFailure<WorkerSessionContext>(unavailableFailure());

  @override
  Future<ReadResult<ReadinessView>> fetchReadiness() => _exec.read(
    'readiness',
    WorkerWireMappers.readiness,
    authoritativeKey: 'readiness',
  );
  @override
  Future<ReadResult<WorkerProfileView>> fetchProfile() async {
    final ctx = _exec.runtime.context;
    if (ctx == null) return _AdapterExecutor.expiredRead<WorkerProfileView>();
    return _exec.read(
      'profile',
      WorkerWireMappers.profile,
      authoritativeKey: 'profile',
      matchesRequested: (profile) => profile.workerId == ctx.workerId,
    );
  }

  @override
  Future<CommandResult> saveProfile(ProfileDraft draft) => _exec.command(
    'save_profile',
    args: {'fields': draft.supportedFields},
    refetchKey: 'profile',
  );
  @override
  Future<CommandResult> setAccountActive(bool active) => _exec.command(
    'set_account_active',
    args: {'active': active},
    refetchKey: 'readiness',
  );
  @override
  Future<ReadResult<List<String>>> fetchWorkAreas() => _exec.read(
    'work_areas',
    WorkerWireMappers.strings,
    authoritativeKey: 'work_areas',
  );
  @override
  Future<CommandResult> saveWorkAreas(WorkAreaDraft draft) => _exec.command(
    'save_work_areas',
    args: {'selectedAreaIds': draft.selectedAreaIds},
    refetchKey: 'work_areas',
  );
  @override
  Future<ReadResult<List<WorkingHoursSlot>>> fetchWorkingHours() => _exec.read(
    'working_hours',
    (body) => WorkerWireMappers.list(
      body,
    ).map(WorkerWireMappers.workingHoursSlot).toList(),
    authoritativeKey: 'working_hours',
  );
  @override
  Future<CommandResult> saveWorkingHours(WorkingHoursDraft draft) =>
      _exec.command(
        'save_working_hours',
        args: {
          'slots': draft.slots
              .map(
                (s) => {
                  'day': s.day,
                  'startLocalTime': s.startLocalTime,
                  'endLocalTime': s.endLocalTime,
                },
              )
              .toList(),
        },
        refetchKey: 'working_hours',
      );
  @override
  Future<ReadResult<StartLocationDraft?>> fetchStartLocation() => _exec.read(
    'start_location',
    (body) => body == null ? null : WorkerWireMappers.startLocation(body),
    authoritativeKey: 'start_location',
  );
  @override
  Future<CommandResult> saveStartLocation(StartLocationDraft draft) =>
      _exec.command(
        'save_start_location',
        args: {
          'source': draft.source,
          'latitude': draft.latitude,
          'longitude': draft.longitude,
          'savedLocationId': draft.savedLocationId,
        },
        refetchKey: 'start_location',
      );
  @override
  Future<ReadResult<Page<String>>> fetchReviews(PageQuery query) => _exec.read(
    'reviews',
    (body) => WorkerWireMappers.page<String>(body, WorkerWireMappers.string),
    args: {'page': query.page, 'perPage': query.perPage},
  );
  @override
  Future<CommandResult> signOut() async => CommandResult(
    status: CommandStatus.rejected,
    reasonCode: 'external_session_logout_required',
  );
}

class WorkerWorkAdapter implements WorkPort {
  WorkerWorkAdapter._(this._exec);
  final _AdapterExecutor _exec;

  @override
  Future<ReadResult<TodayView>> fetchToday() async {
    final ctx = _exec.runtime.context;
    if (ctx == null) return _AdapterExecutor.expiredRead<TodayView>();
    final epoch = _exec.runtime.identityEpoch;
    final cacheRevision = _exec.cache.revision;
    final agenda = await fetchAgenda(AgendaQuery());
    if (!_exec.isCurrentSession(ctx, epoch)) {
      return _AdapterExecutor.expiredRead<TodayView>();
    }
    if (_exec.cache.revision != cacheRevision) {
      return ReadFailure<TodayView>(
        PortFailure(kind: FailureKind.forbidden, reasonCode: 'scope_changed'),
      );
    }
    if (agenda is ReadFailure<AgendaView>) {
      return ReadFailure<TodayView>(agenda.failure);
    }
    final readiness = await WorkerAccessAdapter._(_exec).fetchReadiness();
    if (!_exec.isCurrentSession(ctx, epoch)) {
      return _AdapterExecutor.expiredRead<TodayView>();
    }
    if (_exec.cache.revision != cacheRevision) {
      return ReadFailure<TodayView>(
        PortFailure(kind: FailureKind.forbidden, reasonCode: 'scope_changed'),
      );
    }
    if (readiness is ReadFailure<ReadinessView>) {
      return ReadFailure<TodayView>(readiness.failure);
    }
    final a = agenda as ReadSuccess<AgendaView>;
    final r = readiness as ReadSuccess<ReadinessView>;
    return ReadSuccess<TodayView>(
      value: TodayView(
        agenda: a.value,
        readiness: r.value,
        activeMission: a.value.nextVisit?.scope,
      ),
      fetchedAt: a.fetchedAt,
      freshness: a.freshness,
    );
  }

  @override
  Future<ReadResult<Page<OfferView>>> fetchOffers(OfferQuery query) =>
      _exec.read(
        'offers',
        (body) =>
            WorkerWireMappers.page<OfferView>(body, WorkerWireMappers.offer),
        args: {
          'page': query.page.page,
          'perPage': query.page.perPage,
          'status': query.status,
          'search': query.search,
        },
      );
  @override
  Future<ReadResult<Page<JobSummaryView>>> fetchMyBookings(
    BookingQuery query,
  ) => _exec.read(
    'my_bookings',
    (body) =>
        WorkerWireMappers.page<JobSummaryView>(body, WorkerWireMappers.job),
    args: {
      'page': query.page.page,
      'perPage': query.page.perPage,
      'status': query.status,
      'search': query.search,
    },
  );
  @override
  Future<ReadResult<OfferView>> fetchOffer(String bookingId) => _exec.read(
    'offer',
    WorkerWireMappers.offer,
    args: {'bookingId': requireId(bookingId, 'bookingId')},
    authoritativeKey: _AdapterExecutor.entityKey(bookingId),
    matchesRequested: (offer) =>
        offer.bookingId == bookingId &&
        offer.visitChoices.every((visit) => visit.bookingId == bookingId),
  );
  @override
  Future<CommandResult> submitOfferDecision(
    WorkScope scope,
    OfferDecision decision,
  ) => _exec.command(
    'offer_decision',
    args: {
      'bookingId': scope.bookingId,
      'sessionId': scope.sessionId,
      'assignmentId': scope.assignmentId,
      'kind': decision.kind.name,
      'selectedSessionIds': decision.selectedSessionIds,
    },
    scope: scope,
    refetchKey: _AdapterExecutor.entityKey(scope.bookingId),
  );

  @override
  Future<ReadResult<AgendaView>> fetchAgenda(AgendaQuery query) async {
    final ctx = _exec.runtime.context;
    if (ctx == null) {
      return ReadFailure<AgendaView>(
        PortFailure(
          kind: FailureKind.unauthenticated,
          reasonCode: 'session_expired',
        ),
      );
    }
    final epoch = _exec.runtime.identityEpoch;
    // An implicit current-week key lacks a verified business-date boundary;
    // refuse persistence/fallback until S00 freezes an explicit week identity.
    final mayCache = query.dates != null;
    if (_exec.runtime.connection == ConnectionState.offline) {
      if (!mayCache) {
        return ReadFailure<AgendaView>(
          PortFailure(kind: FailureKind.network, reasonCode: 'offline'),
        );
      }
      final cached = await _exec.cache.readAgenda(
        ctx,
        query.key,
        freshness: ReadFreshness.offline,
      );
      if (!_exec.isCurrentSession(ctx, epoch)) {
        return _AdapterExecutor.expiredRead<AgendaView>();
      }
      return cached ??
          ReadFailure<AgendaView>(
            PortFailure(kind: FailureKind.network, reasonCode: 'offline'),
          );
    }
    final cacheRevision = _exec.cache.revision;
    final result = await _exec.read<AgendaView>(
      'agenda',
      WorkerWireMappers.agenda,
      args: {
        'dateFrom': query.dates?.from,
        'dateTo': query.dates?.to,
        'page': query.page.page,
        'perPage': query.page.perPage,
      },
    );
    if (!_exec.isCurrentSession(ctx, epoch)) {
      return _AdapterExecutor.expiredRead<AgendaView>();
    }
    if (result is ReadSuccess<AgendaView>) {
      if (_exec.cache.revision != cacheRevision) {
        return ReadFailure<AgendaView>(
          PortFailure(
            kind: FailureKind.conflict,
            reasonCode: 'refresh_required',
          ),
        );
      }
      if (mayCache) {
        await _exec.cache.writeAgenda(
          ctx,
          query.key,
          result.value,
          expectedRevision: cacheRevision,
        );
      }
      if (!_exec.isCurrentSession(ctx, epoch)) {
        return _AdapterExecutor.expiredRead<AgendaView>();
      }
      if (_exec.cache.revision != cacheRevision) {
        return ReadFailure<AgendaView>(
          PortFailure(
            kind: FailureKind.conflict,
            reasonCode: 'refresh_required',
          ),
        );
      }
      return result;
    }
    if (result is ReadFailure<AgendaView> &&
        result.failure.kind == FailureKind.network &&
        mayCache) {
      final cached = await _exec.cache.readAgenda(
        ctx,
        query.key,
        freshness: ReadFreshness.stale,
      );
      if (!_exec.isCurrentSession(ctx, epoch)) {
        return _AdapterExecutor.expiredRead<AgendaView>();
      }
      return cached ?? result;
    }
    return result;
  }
}

class WorkerMissionAdapter implements MissionPort {
  WorkerMissionAdapter._(this._exec);
  final _AdapterExecutor _exec;
  Map<String, Object?> _scopeArgs(WorkScope scope) => {
    'bookingId': scope.bookingId,
    'sessionId': scope.sessionId,
    'assignmentId': scope.assignmentId,
  };

  @override
  Future<ReadResult<MissionView>> fetchMission(WorkScope scope) => _exec.read(
    'mission',
    WorkerWireMappers.mission,
    scope: scope,
    args: _scopeArgs(scope),
    authoritativeKey: _AdapterExecutor.scopeDomainKey(scope, 'mission'),
    matchesRequested: (mission) =>
        _AdapterExecutor.sameSelectedScope(scope, mission.scope) &&
        mission.serviceLines.every(
          (line) => _AdapterExecutor.sameSelectedScope(scope, line.scope),
        ),
  );
  @override
  Future<ReadResult<MissionView>> fetchVisitScope(WorkScope scope) =>
      _exec.read(
        'visit_scope',
        WorkerWireMappers.mission,
        scope: scope,
        args: _scopeArgs(scope),
        authoritativeKey: _AdapterExecutor.scopeDomainKey(scope, 'mission'),
        matchesRequested: (mission) =>
            _AdapterExecutor.sameSelectedScope(scope, mission.scope) &&
            mission.serviceLines.every(
              (line) => _AdapterExecutor.sameSelectedScope(scope, line.scope),
            ),
      );
  @override
  Future<ReadResult<InventoryView>> fetchInventory(WorkScope scope) =>
      _exec.read(
        'inventory',
        WorkerWireMappers.inventory,
        scope: scope,
        args: _scopeArgs(scope),
        authoritativeKey: _AdapterExecutor.scopeDomainKey(scope, 'inventory'),
        matchesRequested: (inventory) =>
            _AdapterExecutor.sameSelectedScope(scope, inventory.scope),
      );
  @override
  Future<ReadResult<List<DecisionView>>> fetchDecisions(WorkScope scope) =>
      _exec.read(
        'decisions',
        (body) => WorkerWireMappers.list(
          body,
        ).map(WorkerWireMappers.decision).toList(),
        scope: scope,
        args: _scopeArgs(scope),
        authoritativeKey: _AdapterExecutor.scopeDomainKey(scope, 'decisions'),
        matchesRequested: (decisions) => decisions.every(
          (decision) =>
              _AdapterExecutor.sameSelectedScope(scope, decision.scope),
        ),
      );
  @override
  Future<ReadResult<String?>> fetchVerificationCode(WorkScope scope) =>
      _exec.read(
        'verification_code',
        (body) => body == null ? null : WorkerWireMappers.string(body),
        scope: scope,
        args: _scopeArgs(scope),
      );

  @override
  Future<CommandResult> submit(MissionCommand command) => _exec.command(
    'mission_${command.type}',
    args: {..._scopeArgs(command.scope), ..._commandBody(command)},
    scope: command.scope,
    refetchKey: _AdapterExecutor.scopeDomainKey(
      command.scope,
      switch (command) {
        AcknowledgeEquipmentCommand() || ReturnEquipmentCommand() =>
          'inventory',
        ExtensionDecisionCommand() ||
        OpenTimeEndCommand() ||
        ScheduleChangeCommand() ||
        PriceAdjustmentCommand() => 'decisions',
        _ => 'mission',
      },
    ),
  );

  Map<String, Object?> _commandBody(MissionCommand command) =>
      switch (command) {
        SimpleMissionCommand() => {},
        CompletionReportCommand c => {
          'completionMessage': c.completionMessage,
          'cleaningServices': c.cleaningServices
              .map(
                (s) => {
                  'name': s.name,
                  'label': s.label,
                  'detail': s.detail,
                  'sort': s.sort,
                },
              )
              .toList(),
          'propertiesRooms': c.propertiesRooms
              .map(
                (s) => {
                  'name': s.name,
                  'label': s.label,
                  'detail': s.detail,
                  'sort': s.sort,
                },
              )
              .toList(),
        },
        SpecialServiceStartCommand c => {'lineId': c.lineId},
        SpecialServiceFinishCommand c => {
          'lineId': c.lineId,
          'status': c.status.name,
          'reason': c.reason,
          'afterImages': c.afterImages,
        },
        AcknowledgeEquipmentCommand c => {'reservationId': c.reservationId},
        ReturnEquipmentCommand c => {
          'reservationId': c.reservationId,
          'failureReason': c.failureReason,
        },
        CancellationCommand c => {'reason': c.reason},
        ExtensionDecisionCommand c => {
          'extensionId': c.extensionId,
          'family': c.family.name,
          'decision': c.accept ? 'accepted' : 'rejected',
          'reason': c.reason,
          if (c.additionalMinutes != null)
            'additionalMinutes': c.additionalMinutes,
        },
        OpenTimeEndCommand c => {
          'decision': c.approve ? 'accepted' : 'rejected',
          'reason': c.reason,
        },
        ScheduleChangeCommand c => {
          'changeRequestId': c.changeRequestId,
          'decision': c.approve ? 'accepted' : 'rejected',
          'reason': c.reason,
        },
        PriceAdjustmentCommand c => {
          'reason': c.reason,
          'requestedAmount': {
            'decimal': c.requestedAmount.decimal,
            'currency': c.requestedAmount.currency,
          },
        },
      };
}

class WorkerFinanceAdapter implements FinancePort {
  WorkerFinanceAdapter._(this._exec);
  final _AdapterExecutor _exec;
  @override
  Future<ReadResult<EarningsView>> fetchEarnings(EarningsQuery query) =>
      _exec.read(
        'earnings',
        WorkerWireMappers.earnings,
        args: {
          'scheduledDateFrom': query.dates?.from,
          'scheduledDateTo': query.dates?.to,
          'page': query.page.page,
          'perPage': query.page.perPage,
        },
      );
  @override
  Future<ReadResult<EarningEntryView>> fetchEarning(String entryKey) {
    if (!RegExp(
      r'^(session_assignment|booking_assignment|legacy_booking):[^:]+$',
    ).hasMatch(entryKey)) {
      return Future.value(
        ReadFailure<EarningEntryView>(
          PortFailure(
            kind: FailureKind.validation,
            reasonCode: 'invalid_entry_key',
          ),
        ),
      );
    }
    return _exec.read(
      'earning',
      WorkerWireMappers.earning,
      args: {'entryKey': entryKey},
      matchesRequested: (entry) => entry.key == entryKey,
    );
  }

  @override
  Future<ReadResult<DepositView>> fetchDeposit() =>
      _exec.read('deposit', WorkerWireMappers.deposit);
  @override
  Future<ReadResult<Page<DepositLedgerEntryView>>> fetchDepositLedger(
    LedgerQuery query,
  ) => _exec.read(
    'deposit_ledger',
    (body) => WorkerWireMappers.page<DepositLedgerEntryView>(
      body,
      WorkerWireMappers.depositEntry,
    ),
    args: {
      'page': query.page.page,
      'perPage': query.page.perPage,
      'status': query.status,
    },
  );
  @override
  Future<ReadResult<Page<DisputeView>>> fetchDisputes(DisputeQuery query) =>
      _exec.read(
        'disputes',
        (body) => WorkerWireMappers.page<DisputeView>(
          body,
          WorkerWireMappers.dispute,
        ),
        args: {
          'page': query.page.page,
          'perPage': query.page.perPage,
          'status': query.status,
        },
      );
  @override
  Future<ReadResult<DisputeView>> fetchDispute(String disputeId) => _exec.read(
    'dispute',
    WorkerWireMappers.dispute,
    args: {'disputeId': requireId(disputeId, 'disputeId')},
    authoritativeKey: _AdapterExecutor.entityKey(disputeId),
    matchesRequested: (dispute) => dispute.id == disputeId,
  );
  @override
  Future<CommandResult> postDisputeMessage(String disputeId, String message) {
    requireId(disputeId, 'disputeId');
    if (message.trim().isEmpty || message.length > 2000) {
      return Future.value(
        CommandResult(
          status: CommandStatus.rejected,
          reasonCode: 'invalid_request',
        ),
      );
    }
    return _exec.command(
      'post_dispute_message',
      args: {'disputeId': disputeId, 'message': message},
      entity: disputeId,
      refetchKey: _AdapterExecutor.entityKey(disputeId),
    );
  }
}

class WorkerCommunicationsAdapter implements CommunicationsPort {
  WorkerCommunicationsAdapter._(this._exec);
  final _AdapterExecutor _exec;

  Future<ReadResult<Page<NotificationView>>> _readNotificationPage(
    NotificationQuery query,
    int page,
  ) => _exec.read(
    'notifications',
    WorkerWireMappers.notificationPage,
    args: {
      'page': page,
      'perPage': query.page.perPage,
      'unreadOnly': query.unreadOnly,
    },
  );

  @override
  Future<ReadResult<Page<NotificationView>>> fetchNotifications(
    NotificationQuery query,
  ) async {
    final ctx = _exec.runtime.context;
    if (ctx == null) return _readNotificationPage(query, query.page.page);
    final identityEpoch = _exec.runtime.identityEpoch;
    final pendingAt = _exec.pendingRefetchSequence(ctx, 'notifications');
    if (pendingAt == null ||
        query.page.page != 1 ||
        query.unreadOnly ||
        _exec.commandSequence < pendingAt) {
      return _readNotificationPage(query, query.page.page);
    }

    // Recover a timed-out notification write only after a bounded, complete,
    // unfiltered traversal begun after that write. A partial/paged view is
    // not enough to decide whether the server applied the mutation.
    const maxRecoveryPages = 20;
    final readSequence = _exec.commandSequence;
    final first = await _readNotificationPage(query, 1);
    if (!_exec.isCurrentSession(ctx, identityEpoch)) {
      return _AdapterExecutor.expiredRead<Page<NotificationView>>();
    }
    if (first is! ReadSuccess<Page<NotificationView>>) return first;
    final expectedPages = first.value.lastPage;
    final expectedTotal = first.value.total;
    if (first.value.page != 1 ||
        expectedPages < 1 ||
        expectedPages > maxRecoveryPages) {
      return first;
    }
    for (var page = 2; page <= expectedPages; page++) {
      if (_exec.commandSequence != readSequence) return first;
      final result = await _readNotificationPage(query, page);
      if (!_exec.isCurrentSession(ctx, identityEpoch)) {
        return _AdapterExecutor.expiredRead<Page<NotificationView>>();
      }
      if (result is ReadFailure<Page<NotificationView>>) return result;
      final pageResult = result as ReadSuccess<Page<NotificationView>>;
      if (pageResult.value.page != page ||
          pageResult.value.lastPage != expectedPages ||
          pageResult.value.total != expectedTotal) {
        return ReadFailure<Page<NotificationView>>(
          PortFailure(
            kind: FailureKind.conflict,
            reasonCode: 'pagination_changed',
          ),
        );
      }
    }
    _exec.resolveRefetchAfterCompleteRead(
      ctx,
      'notifications',
      expectedPendingSequence: pendingAt,
      expectedReadSequence: readSequence,
      readStartedAt: readSequence,
    );
    return first;
  }

  @override
  Future<CommandResult> markNotificationRead(String notificationId) =>
      _exec.command(
        'mark_notification_read',
        args: {'notificationId': requireId(notificationId, 'notificationId')},
        refetchKey: 'notifications',
      );
  @override
  Future<CommandResult> deleteNotification(String notificationId) =>
      _exec.command(
        'delete_notification',
        args: {'notificationId': requireId(notificationId, 'notificationId')},
        refetchKey: 'notifications',
      );
  @override
  Future<CommandResult> deleteAllNotifications() => _exec.command(
    'delete_all_notifications',
    args: {},
    refetchKey: 'notifications',
  );
  @override
  Future<ReadResult<List<SupportContactView>>> fetchSupportContacts() =>
      _exec.read(
        'support_contacts',
        (body) => WorkerWireMappers.list(
          body,
        ).map(WorkerWireMappers.supportContact).toList(),
      );
  @override
  Future<CommandResult> sendSos(WorkScope scope, SosDraft draft) {
    if (draft.reason.trim().isEmpty) {
      return Future.value(
        CommandResult(
          status: CommandStatus.rejected,
          reasonCode: 'invalid_request',
          scope: scope,
        ),
      );
    }
    return _exec.command(
      'send_sos',
      args: {
        'bookingId': scope.bookingId,
        'sessionId': scope.sessionId,
        'assignmentId': scope.assignmentId,
        'reason': draft.reason,
        'message': draft.message,
        'latitude': draft.latitude,
        'longitude': draft.longitude,
      },
      scope: scope,
      // No authoritative read can resolve a possibly delivered SOS.
      refetchKey: _AdapterExecutor.scopeDomainKey(scope, 'sos'),
    );
  }
}
