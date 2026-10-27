/// S06 public entry. Root S00 injects authorized ports and route handling.
library;

import 'package:flutter/material.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_worker_order_status.dart';

import '../../contracts/common.dart';
import '../../contracts/models.dart';
import '../../contracts/navigation.dart';
import '../../contracts/ports.dart' as worker_ports;
import '../../contracts/requests.dart';
import '../../design_system/design_system.dart';
import 'catalog_ar.dart';
import 'catalog_en.dart';
import 'mission_sos_window_policy.dart';

/// Candidate visits must originate from a caller's authenticated, server-scoped
/// query. A candidate is never trusted as an authorization to view or mutate.
/// A fresh `fetchVisitScope` is required on each selection.
class MissionModule extends StatefulWidget {
  const MissionModule({
    super.key,
    required this.session,
    required this.scope,
    required this.missionPort,
    required this.runtime,
    required this.onRoute,
    this.authorizedVisitScopes = const [],
    this.languageCode = 'ar',
  });

  final WorkerSessionContext session;
  final WorkScope scope;
  final worker_ports.MissionPort missionPort;
  final worker_ports.WorkerRuntimePort runtime;
  final ValueChanged<RouteIntent> onRoute;
  final List<WorkScope> authorizedVisitScopes;
  final String languageCode;

  @override
  State<MissionModule> createState() => _MissionModuleState();
}

class _MissionModuleState extends State<MissionModule> {
  late WorkScope _scope;
  MissionView? _mission;
  InventoryView? _inventory;
  List<DecisionView> _decisions = const [];
  ReadFreshness? _missionFreshness;
  ReadFreshness? _inventoryFreshness;
  ReadFreshness? _decisionFreshness;
  DateTime? _lastUpdated;
  PortFailure? _readError;
  bool _loading = true;
  bool _busy = false;
  bool _refreshBeforeRetry = false;
  bool _revealingCode = false;
  String? _verifiedCode;
  String? _notification;
  int _epoch = 0;
  final Set<String> _localChecklist = <String>{};
  final Map<String, String> _reasonDrafts = <String, String>{};

  Map<String, String> get _catalog =>
      widget.languageCode.toLowerCase().startsWith('en')
      ? missionEn
      : missionAr;
  String _t(String key) => _catalog[key] ?? _catalog['notProvided']!;
  bool get _sameUser {
    final current = widget.runtime.context;
    return widget.runtime.phase == worker_ports.RuntimePhase.signedIn &&
        current != null &&
        current.userId == widget.session.userId &&
        current.workerId == widget.session.workerId &&
        current.generation == widget.session.generation;
  }

  bool _sameScope(WorkScope expected, WorkScope received) =>
      expected.cacheKey == received.cacheKey;

  bool get _fresh => _missionFreshness == ReadFreshness.fresh;
  bool get _canWrite =>
      _sameUser &&
      widget.runtime.connection == worker_ports.ConnectionState.online &&
      _fresh &&
      !_loading &&
      !_busy &&
      !_refreshBeforeRetry &&
      _readError == null;

  /// Only a currently verified, fresh assignment can leave this feature with
  /// its booking/visit scope. A route selector alone grants no authorization.
  bool get _hasAuthorizedMission =>
      _canWrite && _mission != null && _sameScope(_scope, _mission!.scope);

  bool _can(WorkerAction action) {
    final view = _mission;
    if (!_canWrite || view == null || !_sameScope(_scope, view.scope)) {
      return false;
    }
    if (OperationalContext.executionActions.contains(action) &&
        view.operational.executionOwner != ExecutionOwner.worker) {
      return false;
    }
    if (action == WorkerAction.sendSos &&
        !MissionSosWindowPolicy.permits(view)) {
      return false;
    }
    return view.operational.permits(action);
  }

  @override
  void initState() {
    super.initState();
    _scope = widget.scope;
    _load();
  }

  @override
  void didUpdateWidget(covariant MissionModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope.cacheKey != widget.scope.cacheKey ||
        oldWidget.session.generation != widget.session.generation ||
        oldWidget.session.userId != widget.session.userId ||
        oldWidget.session.workerId != widget.session.workerId ||
        oldWidget.missionPort != widget.missionPort ||
        oldWidget.runtime != widget.runtime) {
      // Even an identical WorkScope is private to the previous session/port.
      // Do not let a new worker see a previous worker's mission for one frame.
      _selectScope(widget.scope, force: true);
    }
  }

  @override
  void dispose() {
    _epoch++;
    super.dispose();
  }

  void _clearScopedData() {
    _mission = null;
    _inventory = null;
    _decisions = const [];
    _readError = null;
    _missionFreshness = null;
    _inventoryFreshness = null;
    _decisionFreshness = null;
    _lastUpdated = null;
    _verifiedCode = null;
    _revealingCode = false;
    _notification = null;
    _refreshBeforeRetry = false;
    _localChecklist.clear();
    _reasonDrafts.clear();
  }

  void _selectScope(WorkScope next, {bool force = false}) {
    if (!force && _scope.cacheKey == next.cacheKey && _mission != null) {
      return;
    }
    _epoch++;
    setState(() {
      _scope = next;
      _clearScopedData();
      _loading = true;
      _busy = false;
    });
    _load();
  }

  Future<void> _load() async {
    final epoch = ++_epoch;
    final requested = _scope;
    if (!_sameUser) {
      setState(() {
        _clearScopedData();
        _loading = false;
        _readError = PortFailure(
          kind: FailureKind.unauthenticated,
          reasonCode: 'session_expired',
        );
      });
      return;
    }
    setState(() {
      _loading = true;
      _readError = null;
      _verifiedCode = null; // Verification is never retained across refreshes.
    });
    bool current() =>
        mounted &&
        epoch == _epoch &&
        requested.cacheKey == _scope.cacheKey &&
        _sameUser;
    try {
      final result = requested.sessionId == null
          ? await widget.missionPort.fetchMission(requested)
          : await widget.missionPort.fetchVisitScope(requested);
      if (!current()) return;
      if (result case ReadFailure<MissionView>(:final failure)) {
        setState(() {
          if (failure.kind == FailureKind.forbidden ||
              failure.kind == FailureKind.notFound ||
              failure.kind == FailureKind.unauthenticated) {
            _clearScopedData();
          }
          _readError = failure;
          _loading = false;
        });
        return;
      }
      if (result is! ReadSuccess<MissionView> ||
          !_sameScope(requested, result.value.scope) ||
          result.value.serviceLines.any(
            (line) => !_sameScope(requested, line.scope),
          )) {
        setState(() {
          _clearScopedData();
          _readError = PortFailure(
            kind: FailureKind.forbidden,
            reasonCode: 'scope_mismatch',
          );
          _loading = false;
        });
        return;
      }
      ReadResult<InventoryView> inventory;
      try {
        inventory = await widget.missionPort.fetchInventory(requested);
      } catch (_) {
        inventory = ReadFailure<InventoryView>(
          PortFailure(
            kind: FailureKind.network,
            reasonCode: 'inventory_read_failed',
          ),
        );
      }
      if (!current()) return;
      ReadResult<List<DecisionView>> decisions;
      try {
        decisions = await widget.missionPort.fetchDecisions(requested);
      } catch (_) {
        decisions = ReadFailure<List<DecisionView>>(
          PortFailure(
            kind: FailureKind.network,
            reasonCode: 'decisions_read_failed',
          ),
        );
      }
      if (!current()) return;

      // Secondary endpoints may revoke the selected visit between reads. A
      // forbidden/removed scope is never kept visible using the earlier result.
      PortFailure? revoked;
      for (final failure in [
        if (inventory is ReadFailure<InventoryView>) inventory.failure,
        if (decisions is ReadFailure<List<DecisionView>>) decisions.failure,
      ]) {
        if (failure.kind == FailureKind.forbidden ||
            failure.kind == FailureKind.notFound ||
            failure.kind == FailureKind.unauthenticated) {
          revoked = failure;
          break;
        }
      }
      if (revoked != null) {
        setState(() {
          _clearScopedData();
          _readError = revoked;
          _loading = false;
        });
        return;
      }

      InventoryView? safeInventory;
      ReadFreshness? inventoryFreshness;
      if (inventory is ReadSuccess<InventoryView> &&
          _sameScope(requested, inventory.value.scope)) {
        safeInventory = inventory.value;
        inventoryFreshness = inventory.freshness;
      }
      List<DecisionView> safeDecisions = const [];
      ReadFreshness? decisionFreshness;
      if (decisions is ReadSuccess<List<DecisionView>> &&
          decisions.value.every(
            (decision) => _sameScope(requested, decision.scope),
          )) {
        safeDecisions = decisions.value;
        decisionFreshness = decisions.freshness;
      }
      setState(() {
        _mission = result.value;
        _missionFreshness = result.freshness;
        _lastUpdated = result.fetchedAt;
        _inventory = safeInventory;
        _inventoryFreshness = inventoryFreshness;
        _decisions = safeDecisions;
        _decisionFreshness = decisionFreshness;
        _refreshBeforeRetry = false;
        _readError = null;
        _loading = false;
      });
    } catch (_) {
      if (!current()) return;
      setState(() {
        _loading = false;
        _readError = PortFailure(
          kind: FailureKind.network,
          reasonCode: 'mission_read_failed',
        );
      });
    }
  }

  Future<void> _submit(WorkerAction action, MissionCommand command) async {
    if (!_can(action) || !_sameScope(command.scope, _scope)) return;
    final epoch = _epoch;
    setState(() {
      _busy = true;
      _notification = null;
    });
    CommandResult outcome;
    try {
      outcome = await widget.missionPort.submit(command);
    } catch (_) {
      outcome = CommandResult(status: CommandStatus.outcomeUnknown);
    }
    if (!mounted || epoch != _epoch || !_sameUser) return;
    setState(() => _busy = false);
    if (outcome.scope != null && !_sameScope(outcome.scope!, _scope)) {
      setState(() {
        _refreshBeforeRetry = true;
        _notification = _t('unknown');
      });
      await _load();
      return;
    }
    if (outcome.status == CommandStatus.confirmed) {
      // Never transition the mission locally. The server returns the new state.
      setState(() {
        _reasonDrafts.clear();
        _notification = _t('confirmed');
      });
      await _load();
    } else if (outcome.status == CommandStatus.outcomeUnknown) {
      setState(() {
        _refreshBeforeRetry = true;
        _notification = _t('unknown');
      });
      await _load();
    } else {
      setState(
        () => _notification = outcome.fieldErrors.isNotEmpty
            ? _t('validation')
            : _reason(outcome.reasonCode) ?? _t('rejected'),
      );
      // A rejected command may be based on stale ownership or visit state.
      await _load();
    }
  }

  String? _reason(String? code) {
    if (code == null) return null;
    return _catalog[code] ?? _t('blocked');
  }

  String _statusLabel(String status) {
    if (status == 'rejected') return _t('rejected_status');
    return _catalog[status] ??
        (widget.languageCode.toLowerCase().startsWith('en')
            ? status
            : arabicCleaningStatusLabel(status));
  }

  Widget? _terminalStatus(MissionView mission) {
    final status = mission.status;
    final tone = switch (status) {
      'completed' => WrStatusTone.success,
      'cancelled' ||
      'skipped' ||
      'disputed' ||
      'rejected' => WrStatusTone.warning,
      'rework' || 'waiting_customer' => WrStatusTone.info,
      _ => null,
    };
    if (tone == null) return null;
    return WrEligibilityNotice(
      title: _statusLabel(status),
      message: _t('statusDetail'),
      tone: tone,
    );
  }

  String _failureText(PortFailure failure) => switch (failure.kind) {
    FailureKind.unauthenticated => _t('unauthorized'),
    FailureKind.forbidden => _t('forbidden'),
    FailureKind.notFound => _t('notFound'),
    FailureKind.conflict => _t('conflict'),
    FailureKind.validation => _t('validation'),
    FailureKind.network => _t('network'),
    FailureKind.server => _t('error'),
  };

  Future<void> _simple(WorkerAction action, SimpleMissionAction kind) =>
      _submit(action, SimpleMissionCommand(_scope, kind));

  void _go(WorkerDestination destination) {
    if (!_sameUser) {
      return;
    }
    // SOS must be explicitly permitted for this assignment, but does not
    // depend on the mission's execution owner/capability.
    if (destination == WorkerDestination.sos && !_can(WorkerAction.sendSos)) {
      return;
    }
    // Generic support remains reachable after 403/404, without exposing or
    // forwarding an unverified booking/visit identifier to another feature.
    widget.onRoute(
      RouteIntent(
        destination: destination,
        origin: RouteOrigin.mission,
        scope: _hasAuthorizedMission ? _scope : null,
      ),
    );
  }

  Future<void> _showCode() async {
    if (!_can(WorkerAction.viewVerificationCode)) return;
    final epoch = _epoch;
    setState(() {
      _revealingCode = true;
      _verifiedCode = null;
    });
    try {
      final result = await widget.missionPort.fetchVerificationCode(_scope);
      if (!mounted || epoch != _epoch || !_sameUser) return;
      setState(() {
        _revealingCode = false;
        if (_can(WorkerAction.viewVerificationCode) &&
            result is ReadSuccess<String?> &&
            result.freshness == ReadFreshness.fresh) {
          _verifiedCode = result.value;
        }
      });
    } catch (_) {
      if (!mounted || epoch != _epoch) return;
      setState(() => _revealingCode = false);
    }
  }

  Future<void> _withReason({
    required String title,
    required bool requiredReason,
    required void Function(String reason) onSubmit,
    String? primaryLabel,
    String? fieldLabel,
    String? draftIdentity,
  }) async {
    if (!_canWrite) return;
    final scopeKey = _scope.cacheKey;
    final generation = _epoch;
    final draftKey = '${_scope.cacheKey}:${draftIdentity ?? title}';
    final controller = TextEditingController(text: _reasonDrafts[draftKey]);
    var invalid = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, localSetState) => WrSheetFrame(
          title: title,
          primaryLabel: primaryLabel ?? _t('submit'),
          onPrimary: () {
            final reason = controller.text.trim();
            if (requiredReason && reason.isEmpty) {
              localSetState(() => invalid = true);
              return;
            }
            Navigator.of(sheetContext).pop();
            if (mounted &&
                generation == _epoch &&
                scopeKey == _scope.cacheKey &&
                _canWrite) {
              _reasonDrafts[draftKey] = reason;
              onSubmit(reason);
            }
          },
          secondaryLabel: _t('close'),
          onSecondary: () => Navigator.of(sheetContext).pop(),
          child: WrField(
            label: fieldLabel ?? _t('reason'),
            controller: controller,
            errorText: invalid ? _t('reasonRequired') : null,
          ),
        ),
      ),
    );
    controller.dispose();
  }

  void _decision(DecisionView decision, bool accept) {
    if (!_sameScope(decision.scope, _scope) ||
        !_canWrite ||
        _decisionFreshness != ReadFreshness.fresh) {
      return;
    }
    final action = accept
        ? WorkerAction.acceptExtension
        : WorkerAction.rejectExtension;
    if (decision.extensionFamily != null && _can(action)) {
      _withReason(
        title: accept ? _t('approve') : _t('decline'),
        requiredReason: false,
        primaryLabel: accept ? _t('approve') : _t('decline'),
        draftIdentity: 'extension:${decision.requestId}:$accept',
        onSubmit: (reason) => _submit(
          action,
          ExtensionDecisionCommand(
            _scope,
            extensionId: decision.requestId,
            family: decision.extensionFamily!,
            accept: accept,
            reason: reason.isEmpty ? null : reason,
          ),
        ),
      );
    } else if (decision.kind == 'open_time_end' &&
        _can(WorkerAction.decideOpenTimeEnd)) {
      _withReason(
        title: accept ? _t('approve') : _t('decline'),
        requiredReason: false,
        primaryLabel: accept ? _t('approve') : _t('decline'),
        draftIdentity: 'open_time_end:$accept',
        onSubmit: (reason) => _submit(
          WorkerAction.decideOpenTimeEnd,
          OpenTimeEndCommand(
            _scope,
            approve: accept,
            reason: reason.isEmpty ? null : reason,
          ),
        ),
      );
    } else if (decision.kind == 'schedule_change' &&
        _can(WorkerAction.decideScheduleChange)) {
      _withReason(
        title: accept ? _t('approve') : _t('decline'),
        requiredReason: false,
        primaryLabel: accept ? _t('approve') : _t('decline'),
        draftIdentity: 'schedule:${decision.requestId}:$accept',
        onSubmit: (reason) => _submit(
          WorkerAction.decideScheduleChange,
          ScheduleChangeCommand(
            _scope,
            changeRequestId: decision.requestId,
            approve: accept,
            reason: reason.isEmpty ? null : reason,
          ),
        ),
      );
    }
  }

  Widget _space() => const SizedBox(height: WrSpace.md);

  Widget _section(String title, Widget child, {String? subtitle}) =>
      WrSectionPanel(title: title, subtitle: subtitle, child: child);

  Widget _statusInfo(MissionView mission) {
    final owner = switch (mission.operational.executionOwner) {
      ExecutionOwner.worker => _t('ownerWorker'),
      ExecutionOwner.supervisor => _t('ownerSupervisor'),
      null => _t('ownerUnknown'),
    };
    return _section(
      _t('overview'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WrListRow(title: _t('booking'), subtitle: _scope.bookingId),
          if (_scope.sessionId != null)
            WrListRow(title: _t('visit'), subtitle: _scope.sessionId),
          WrListRow(title: _t('stage'), subtitle: mission.stage),
          WrListRow(
            title: _t('assignment'),
            subtitle: mission.ownAssignmentStatus,
          ),
          WrStatusBadge(label: '${_statusLabel(mission.status)} · $owner'),
          if (_terminalStatus(mission) != null) ...[
            const SizedBox(height: WrSpace.sm),
            _terminalStatus(mission)!,
          ],
          if (!mission.operational.executionCapability) ...[
            const SizedBox(height: WrSpace.sm),
            WrEligibilityNotice(
              title: _t('executionBlocked'),
              message: mission.operational.blockedReasons.isEmpty
                  ? _t('ownerNotice')
                  : mission.operational.blockedReasons
                        .map((reason) => _reason(reason) ?? _t('blocked'))
                        .join(' · '),
            ),
          ],
          if (mission.waitingReasons.isNotEmpty) ...[
            const SizedBox(height: WrSpace.sm),
            WrEligibilityNotice(
              title: _t('waiting'),
              message: mission.waitingReasons
                  .map((reason) => _reason(reason) ?? _t('waiting'))
                  .join(' · '),
            ),
          ],
          if (mission.customerLocation != null)
            WrListRow(
              title: _t('location'),
              subtitle: mission.customerLocation,
            ),
        ],
      ),
    );
  }

  Widget _visitSelector() {
    final choices = widget.authorizedVisitScopes
        .where(
          (candidate) =>
              candidate.bookingId == _scope.bookingId &&
              (candidate.sessionId != null || _scope.sessionId == null),
        )
        .toList();
    if (choices.isEmpty) return const SizedBox.shrink();
    return _section(
      _t('chooseVisit'),
      Wrap(
        spacing: WrSpace.xs,
        runSpacing: WrSpace.xs,
        children: [
          for (final candidate in choices)
            ChoiceChip(
              label: Text(candidate.sessionId ?? _t('legacy')),
              selected: candidate.cacheKey == _scope.cacheKey,
              onSelected: _busy || _loading
                  ? null
                  : (_) => _selectScope(candidate),
            ),
        ],
      ),
    );
  }

  Widget _attendance() => _section(
    _t('attendance'),
    Column(
      children: [
        WrActionButton(
          label: _t('startTravel'),
          onPressed: _can(WorkerAction.startTravel)
              ? () => _simple(
                  WorkerAction.startTravel,
                  SimpleMissionAction.startTravel,
                )
              : null,
          disabledExplanation: _t('blocked'),
          busy: _busy,
          busyLabel: _t('busy'),
          leadingIcon: Icons.directions_walk_outlined,
        ),
        const SizedBox(height: WrSpace.xs),
        WrActionButton(
          label: _t('arrive'),
          role: WrActionRole.secondary,
          onPressed: _can(WorkerAction.arrive)
              ? () => _simple(WorkerAction.arrive, SimpleMissionAction.arrive)
              : null,
          disabledExplanation: _t('blocked'),
          busy: _busy,
          busyLabel: _t('busy'),
          leadingIcon: Icons.location_on_outlined,
        ),
      ],
    ),
  );

  Widget _timeline(MissionView mission) => _section(
    _t('timeline'),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mission.startedAt != null)
          WrListRow(
            title: _t('startedAt'),
            subtitle: '${mission.startedAt!.toUtc().toIso8601String()} UTC',
            subtitleDirection: TextDirection.ltr,
          ),
        if (mission.billableStartAt != null)
          WrListRow(
            title: _t('billableStartAt'),
            subtitle:
                '${mission.billableStartAt!.toUtc().toIso8601String()} UTC',
            subtitleDirection: TextDirection.ltr,
          ),
        if (mission.expiresAt != null)
          WrListRow(
            title: _t('expiresAt'),
            subtitle: '${mission.expiresAt!.toUtc().toIso8601String()} UTC',
            subtitleDirection: TextDirection.ltr,
          ),
        if (mission.startedAt == null &&
            mission.billableStartAt == null &&
            mission.expiresAt == null)
          Text(_t('notProvided'), style: WrType.support),
      ],
    ),
  );

  Widget _verification() => _section(
    _t('code'),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t('codeInstructions'), style: WrType.support),
        const SizedBox(height: WrSpace.sm),
        if (_verifiedCode != null && _can(WorkerAction.viewVerificationCode))
          Semantics(
            label: _t('confirmedCode'),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                _verifiedCode!,
                textAlign: TextAlign.center,
                style: WrType.keyValue,
              ),
            ),
          ),
        WrActionButton(
          label: _t('showCode'),
          busy: _revealingCode,
          busyLabel: _t('loading'),
          onPressed: _can(WorkerAction.viewVerificationCode) && !_revealingCode
              ? _showCode
              : null,
          role: WrActionRole.secondary,
        ),
        const SizedBox(height: WrSpace.sm),
        WrActionButton(
          label: _t('startWork'),
          onPressed: _can(WorkerAction.confirmWorkStart)
              ? () => _simple(
                  WorkerAction.confirmWorkStart,
                  SimpleMissionAction.confirmWorkStart,
                )
              : null,
          busy: _busy,
          busyLabel: _t('busy'),
          disabledExplanation: _t('executionBlocked'),
        ),
      ],
    ),
  );

  Widget _services(MissionView mission) => _section(
    _t('services'),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WrEligibilityNotice(
          title: _t('localDraft'),
          message: _t('completionWarning'),
          tone: WrStatusTone.info,
        ),
        for (var i = 0; i < mission.ownServices.length; i++)
          Material(
            color: WrColors.surface,
            child: CheckboxListTile(
              key: ValueKey('service_draft_$i'),
              title: Text(mission.ownServices[i]),
              subtitle: _localChecklist.contains('service_$i')
                  ? Text(_t('draftDone'))
                  : null,
              value: _localChecklist.contains('service_$i'),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _localChecklist.add('service_$i');
                } else {
                  _localChecklist.remove('service_$i');
                }
              }),
            ),
          ),
        for (var i = 0; i < mission.ownRooms.length; i++)
          Material(
            color: WrColors.surface,
            child: CheckboxListTile(
              key: ValueKey('room_draft_$i'),
              title: Text(mission.ownRooms[i]),
              value: _localChecklist.contains('room_$i'),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _localChecklist.add('room_$i');
                } else {
                  _localChecklist.remove('room_$i');
                }
              }),
            ),
          ),
        for (final line in mission.serviceLines) _serviceLine(line),
        if (mission.ownServices.isEmpty &&
            mission.ownRooms.isEmpty &&
            mission.serviceLines.isEmpty)
          Text(_t('noDetails'), style: WrType.support),
      ],
    ),
  );

  Widget _serviceLine(MissionServiceLineView line) {
    final scoped = _sameScope(_scope, line.scope);
    final start =
        scoped &&
        line.allowedActions.contains(WorkerAction.startSpecialService) &&
        _can(WorkerAction.startSpecialService);
    final finish =
        scoped &&
        line.allowedActions.contains(WorkerAction.finishSpecialService) &&
        _can(WorkerAction.finishSpecialService);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WrListRow(title: line.label, subtitle: line.status),
        if (start)
          WrActionButton(
            label: _t('startService'),
            role: WrActionRole.secondary,
            onPressed: () => _submit(
              WorkerAction.startSpecialService,
              SpecialServiceStartCommand(_scope, lineId: line.lineId),
            ),
          ),
        if (finish) ...[
          WrActionButton(
            label: _t('finishService'),
            role: WrActionRole.secondary,
            onPressed: () => _submit(
              WorkerAction.finishSpecialService,
              SpecialServiceFinishCommand(
                _scope,
                lineId: line.lineId,
                status: SpecialServiceFinishStatus.completed,
              ),
            ),
          ),
          WrActionButton(
            label: _t('unableService'),
            role: WrActionRole.secondary,
            onPressed: () => _withReason(
              title: _t('unableService'),
              requiredReason: true,
              primaryLabel: _t('unableService'),
              draftIdentity: 'unable:${line.lineId}',
              onSubmit: (reason) => _submit(
                WorkerAction.finishSpecialService,
                SpecialServiceFinishCommand(
                  _scope,
                  lineId: line.lineId,
                  status: SpecialServiceFinishStatus.unable,
                  reason: reason,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _materials() => _section(
    _t('inventory'),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_inventory == null)
          Text(_t('inventoryUnavailable'), style: WrType.support),
        if (_inventory != null && _inventory!.items.isEmpty)
          Text(_t('noDetails'), style: WrType.support),
        for (final item in _inventory?.items ?? <InventoryItemView>[])
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WrListRow(
                title: item.name,
                subtitle: '${item.quantity} · ${item.custodyState}',
              ),
              if (_inventoryFreshness == ReadFreshness.fresh &&
                  item.reservationId != null &&
                  item.allowedActions.contains(
                    WorkerAction.acknowledgeEquipment,
                  ) &&
                  _can(WorkerAction.acknowledgeEquipment))
                WrActionButton(
                  label: _t('acknowledge'),
                  role: WrActionRole.secondary,
                  onPressed: () => _submit(
                    WorkerAction.acknowledgeEquipment,
                    AcknowledgeEquipmentCommand(
                      _scope,
                      reservationId: item.reservationId!,
                    ),
                  ),
                ),
              if (_inventoryFreshness == ReadFreshness.fresh &&
                  item.reservationId != null &&
                  item.allowedActions.contains(WorkerAction.returnEquipment) &&
                  _can(WorkerAction.returnEquipment))
                WrActionButton(
                  label: _t('return'),
                  role: WrActionRole.secondary,
                  onPressed: () => _submit(
                    WorkerAction.returnEquipment,
                    ReturnEquipmentCommand(
                      _scope,
                      reservationId: item.reservationId!,
                    ),
                  ),
                ),
            ],
          ),
        if (_can(WorkerAction.receiveMaterials))
          WrActionButton(
            label: _t('receiveMaterials'),
            role: WrActionRole.secondary,
            onPressed: () => _simple(
              WorkerAction.receiveMaterials,
              SimpleMissionAction.receiveMaterials,
            ),
          ),
      ],
    ),
  );

  Widget _decisionCard(DecisionView decision) {
    final same = _sameScope(_scope, decision.scope);
    final actionable =
        same &&
        decision.status == 'pending' &&
        decision.decisionActor == 'worker' &&
        _decisionFreshness == ReadFreshness.fresh;
    final extension = decision.extensionFamily != null;
    final canAccept =
        actionable &&
        ((extension && _can(WorkerAction.acceptExtension)) ||
            (decision.kind == 'open_time_end' &&
                _can(WorkerAction.decideOpenTimeEnd)) ||
            (decision.kind == 'schedule_change' &&
                _can(WorkerAction.decideScheduleChange)));
    final canReject =
        actionable &&
        ((extension && _can(WorkerAction.rejectExtension)) ||
            (decision.kind == 'open_time_end' &&
                _can(WorkerAction.decideOpenTimeEnd)) ||
            (decision.kind == 'schedule_change' &&
                _can(WorkerAction.decideScheduleChange)));
    return WrSectionPanel(
      title: decision.kind,
      subtitle: decision.status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in decision.currentValues.entries)
            if (entry.value != null)
              WrListRow(
                title: '${_t('current')} · ${entry.key}',
                subtitle: entry.value,
              ),
          for (final entry in decision.proposedValues.entries)
            if (entry.value != null)
              WrListRow(
                title: '${_t('proposed')} · ${entry.key}',
                subtitle: entry.value,
              ),
          Text(_t('price'), style: WrType.support),
          WrAmountText(
            amount: decision.pricedAmount,
            unavailableLabel: _t('unavailablePrice'),
          ),
          if (canAccept || canReject) ...[
            const SizedBox(height: WrSpace.sm),
            if (canAccept)
              WrActionButton(
                label: _t('approve'),
                onPressed: () => _decision(decision, true),
              ),
            if (canReject) ...[
              const SizedBox(height: WrSpace.xs),
              WrActionButton(
                label: _t('decline'),
                role: WrActionRole.secondary,
                onPressed: () => _decision(decision, false),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _decisionsPanel() => _section(
    _t('decisions'),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_decisions.isEmpty) Text(_t('noDecisions'), style: WrType.support),
        for (final decision in _decisions) ...[
          _decisionCard(decision),
          const SizedBox(height: WrSpace.xs),
        ],
        if (_can(WorkerAction.requestPriceAdjustment))
          WrEligibilityNotice(
            title: _t('priceRequestUnavailable'),
            message: _t('unavailablePrice'),
            tone: WrStatusTone.info,
          ),
      ],
    ),
  );

  Widget _handover() => _section(
    _t('completion'),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_t('completionWarning'), style: WrType.support),
        const SizedBox(height: WrSpace.sm),
        WrActionButton(
          label: _t('complete'),
          onPressed:
              _scope.sessionId != null && _can(WorkerAction.submitCompletion)
              ? () => _withReason(
                  title: _t('completion'),
                  requiredReason: false,
                  primaryLabel: _t('complete'),
                  fieldLabel: _t('completionNote'),
                  draftIdentity: 'handover',
                  onSubmit: (note) => _submit(
                    WorkerAction.submitCompletion,
                    CompletionReportCommand(
                      _scope,
                      completionMessage: note.isEmpty ? null : note,
                    ),
                  ),
                )
              : null,
          busy: _busy,
          busyLabel: _t('busy'),
          disabledExplanation: _t('noAuthority'),
        ),
        if (_can(WorkerAction.cancelAssignment)) ...[
          const SizedBox(height: WrSpace.sm),
          WrActionButton(
            label: _t('cancelAssignment'),
            role: WrActionRole.destructive,
            onPressed: () => _withReason(
              title: _t('cancelWarning'),
              requiredReason: true,
              primaryLabel: _t('cancelAssignment'),
              draftIdentity: 'cancel',
              onSubmit: (reason) => _submit(
                WorkerAction.cancelAssignment,
                CancellationCommand(_scope, reason: reason),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final error = _readError;
    final view = _sameUser ? _mission : null;
    final panel = !_sameUser
        ? WrFeedbackPanel(
            kind: WrFeedbackKind.forbidden,
            title: _t('unauthorized'),
          )
        : error != null &&
              (view == null ||
                  error.kind == FailureKind.forbidden ||
                  error.kind == FailureKind.notFound ||
                  error.kind == FailureKind.unauthenticated)
        ? WrFeedbackPanel(
            kind: error.kind == FailureKind.forbidden
                ? WrFeedbackKind.forbidden
                : WrFeedbackKind.initialError,
            title: _failureText(error),
            retryLabel: _t('retry'),
            onRetry:
                error.kind == FailureKind.forbidden ||
                    error.kind == FailureKind.unauthenticated
                ? null
                : _load,
          )
        : view == null
        ? WrFeedbackPanel(
            kind: _loading ? WrFeedbackKind.loading : WrFeedbackKind.empty,
            title: _loading ? _t('loading') : _t('empty'),
          )
        : _content(view);
    return Directionality(
      textDirection: widget.languageCode.toLowerCase().startsWith('en')
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: WrPageFrame(
        title: _t('title'),
        subtitle: _scope.sessionId == null
            ? '${_t('booking')} ${_scope.bookingId}'
            : '${_t('booking')} ${_scope.bookingId} · ${_t('visit')} ${_scope.sessionId}',
        headerAction: WrIconAction(
          icon: Icons.refresh,
          label: _t('refresh'),
          onPressed: _loading || _busy || !_sameUser ? null : _load,
          busy: _loading,
          busyLabel: _t('loading'),
        ),
        bottomAction: Row(
          children: [
            Expanded(
              child: WrActionButton(
                label: _t('support'),
                role: WrActionRole.secondary,
                onPressed: _sameUser
                    ? () => _go(WorkerDestination.support)
                    : null,
              ),
            ),
            if (view == null || MissionSosWindowPolicy.permits(view)) ...[
              const SizedBox(width: WrSpace.xs),
              Expanded(
                child: WrActionButton(
                  label: _t('sos'),
                  role: WrActionRole.destructive,
                  onPressed: _can(WorkerAction.sendSos)
                      ? () => _go(WorkerDestination.sos)
                      : null,
                ),
              ),
            ],
          ],
        ),
        child: panel,
      ),
    );
  }

  Widget _content(MissionView view) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_loading) ...[
        WrEligibilityNotice(
          title: _t('refreshing'),
          message: _t('noAuthority'),
          tone: WrStatusTone.info,
        ),
        _space(),
      ],
      if (widget.runtime.connection != worker_ports.ConnectionState.online ||
          _missionFreshness == ReadFreshness.offline) ...[
        WrEligibilityNotice(title: _t('off'), message: _t('noAuthority')),
        _space(),
      ] else if (!_fresh) ...[
        WrEligibilityNotice(title: _t('stale'), message: _t('noAuthority')),
        _space(),
      ],
      if (_refreshBeforeRetry) ...[
        WrEligibilityNotice(title: _t('unknown'), message: _t('refresh')),
        _space(),
      ],
      if (_notification != null) ...[
        WrEligibilityNotice(title: _notification!, message: _t('refresh')),
        _space(),
      ],
      if (_readError != null) ...[
        WrFeedbackPanel(
          kind: WrFeedbackKind.refreshError,
          title: _failureText(_readError!),
          retryLabel: _t('retry'),
          onRetry: _load,
        ),
        _space(),
      ],
      if (_lastUpdated != null) ...[
        Text(
          '${_t('updatedAt')}: ${_lastUpdated!.toUtc().toIso8601String()} UTC',
          textDirection: TextDirection.ltr,
          style: WrType.support,
        ),
        _space(),
      ],
      _visitSelector(),
      _space(),
      _statusInfo(view),
      _space(),
      _attendance(),
      _space(),
      _timeline(view),
      _space(),
      _verification(),
      _space(),
      _services(view),
      _space(),
      _materials(),
      _space(),
      _decisionsPanel(),
      _space(),
      _handover(),
      _space(),
      _section(
        _t('schedule'),
        Text(_t('scheduleUnavailable'), style: WrType.support),
      ),
    ],
  );
}
