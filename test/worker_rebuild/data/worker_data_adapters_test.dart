import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart'
    as c;
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/ports.dart'
    as p;
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/data/port_adapters.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/data/runtime_adapter.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/data/transport.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/data/wire_mappers.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/data/work_summary_cache.dart';

final _ctx = c.WorkerSessionContext(
  userId: 'u-test',
  workerId: 'w-test',
  generation: 'gen-one',
);
final _scope = c.WorkScope(
  bookingId: 'b-20',
  sessionId: 'visit-1',
  assignmentId: 'assigned-1',
);

class _FakeTransport implements WorkerReadTransport, WorkerWriteTransport {
  final reads = <String, WorkerWireResponse>{};
  final writes = <String, WorkerWireResponse>{};
  final readHandlers =
      <String, WorkerWireResponse Function(WorkerWireRequest request)>{};
  final requests = <WorkerWireRequest>[];
  final pendingReads = <String, Completer<WorkerWireResponse>>{};
  final readStarted = <String, Completer<void>>{};
  final pendingReadsByRequest = <String, Completer<WorkerWireResponse>>{};
  final readStartedByRequest = <String, Completer<void>>{};
  WorkerTransportFault? readFault;
  WorkerTransportFault? writeFault;
  @override
  Future<WorkerWireResponse> read(WorkerWireRequest request) async {
    requests.add(request);
    final requestKey = '${request.operation}:${request.arguments['page']}';
    final requestStarted = readStartedByRequest[requestKey];
    if (requestStarted != null && !requestStarted.isCompleted) {
      requestStarted.complete();
    }
    if (pendingReadsByRequest[requestKey] case final waitingRequest?) {
      return waitingRequest.future;
    }
    final started = readStarted[request.operation];
    if (started != null && !started.isCompleted) started.complete();
    if (pendingReads[request.operation] case final waiting?) {
      return waiting.future;
    }
    if (readFault case final fault?) throw fault;
    final handler = readHandlers[request.operation];
    if (handler != null) return handler(request);
    return reads[request.operation] ?? const WorkerWireResponse(404, null);
  }

  @override
  Future<WorkerWireResponse> write(WorkerWireRequest request) async {
    requests.add(request);
    if (writeFault case final fault?) throw fault;
    return writes[request.operation] ?? const WorkerWireResponse(404, null);
  }
}

class _DelayedStorage implements WorkSummaryStorage {
  final data = MemoryWorkSummaryStorage();
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<String?> read(String key) => data.read(key);
  @override
  Future<void> write(String key, String value) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    await data.write(key, value);
  }

  @override
  Future<void> delete(String key) => data.delete(key);
  @override
  Future<Iterable<String>> keys() => data.keys();
}

class _DelayedKeysStorage implements WorkSummaryStorage {
  final data = MemoryWorkSummaryStorage();
  final started = Completer<void>();
  final release = Completer<void>();
  bool blockNextKeys = true;
  @override
  Future<String?> read(String key) => data.read(key);
  @override
  Future<void> write(String key, String value) => data.write(key, value);
  @override
  Future<void> delete(String key) => data.delete(key);
  @override
  Future<Iterable<String>> keys() async {
    if (blockNextKeys) {
      blockNextKeys = false;
      started.complete();
      await release.future;
    }
    return data.keys();
  }
}

class _DelayedReadStorage implements WorkSummaryStorage {
  final data = MemoryWorkSummaryStorage();
  final started = Completer<void>();
  final release = Completer<void>();
  bool blockNextRead = false;
  @override
  Future<String?> read(String key) async {
    final captured = await data.read(key);
    if (blockNextRead) {
      blockNextRead = false;
      started.complete();
      await release.future;
    }
    return captured;
  }

  @override
  Future<void> write(String key, String value) => data.write(key, value);
  @override
  Future<void> delete(String key) => data.delete(key);
  @override
  Future<Iterable<String>> keys() => data.keys();
}

AgendaQuery _datedAgenda() => AgendaQuery(
  dates: DateRange(from: '2026-10-23', to: '2026-10-23'),
);

Map<String, Object?> _readinessWire() => {
  'accountState': 'active',
  'completenessItems': <String>[],
  'canReceiveRequests': true,
  'financialRestrictionCodes': <String>[],
  'remedyDestinations': <String, String>{},
};

Map<String, Object?> _profileWire({String workerId = 'w-test'}) => {
  'workerId': workerId,
  'displayName': 'Worker fixture',
  'accountState': 'active',
  'editableValues': {'displayName': 'Worker fixture'},
  'workPreferences': <String, String>{},
  'phone': 'fixture-phone',
  'reviewAverage': null,
  'trustScore': null,
};

Map<String, Object?> _row({
  String bookingId = 'b-20',
  String session = 'visit-1',
  String assignment = 'assigned-1',
  String assignmentStatus = 'assigned',
  String status = 'active',
  String? phone,
}) => {
  'key': 'key-$session',
  'scope': {
    'bookingId': bookingId,
    'sessionId': session,
    'assignmentId': assignment,
  },
  'scheduledDate': '2026-10-23',
  'status': status,
  'ownAssignmentStatus': assignmentStatus,
  'work': {
    'label': 'Cleaning',
    'type': 'regular',
    'area': 'Aleppo',
    'locationSummary': 'Private building',
  },
  'operationalContext': {
    'executionOwner': 'worker',
    'executionCapability': true,
    'canRecordAttendance': true,
    'allowedActions': ['view', 'confirm_work_start'],
    'blockedReasons': <String>[],
  },
  'startsAt': '2026-10-23T06:00:00Z',
  'endsAt': null,
  'customerPhone': phone ?? 'never-store-phone',
  'customerAddress': 'never-store-address',
  'gps': {'latitude': 12.34, 'longitude': 56.78},
  'workerAmount': {'decimal': '999.98', 'currency': 'SYP'},
  'token': 'never-store-token',
  'otp': 'never-store-otp',
  'dispute': {'body': 'never-store-dispute'},
};

Map<String, Object?> _agenda(List<Object?> rows, {int? total}) => {
  'data': rows,
  'meta': {'page': 1, 'lastPage': 1, 'total': total ?? rows.length},
  'summary': {'activeVisits': total ?? rows.length, 'nextVisit': null},
  'timezone': 'Asia/Damascus',
};

Map<String, Object?> _missionWire() => {
  'scope': {
    'bookingId': 'b-20',
    'sessionId': 'visit-1',
    'assignmentId': 'assigned-1',
  },
  'status': 'active',
  'stage': 'travel',
  'ownAssignmentStatus': 'assigned',
  'operationalContext': {
    'executionOwner': 'supervisor',
    'executionCapability': false,
    'canRecordAttendance': true,
    'allowedActions': ['view', 'start_travel', 'confirm_work_start'],
    'blockedReasons': ['supervisor_managed'],
  },
  'ownServices': ['Cleaning'],
  'ownRooms': ['Living room'],
  'waitingReasons': [],
  'customerPhone': 'very-private',
};

Future<WorkerDataAdapters> _started(
  _FakeTransport transport, {
  WorkSummaryStorage? storage,
  DateTime Function()? clock,
}) async {
  final bundle = WorkerDataAdapters(
    reads: transport,
    writes: transport,
    cacheStorage: storage,
    clock: clock,
  );
  await bundle.runtime.replaceIdentity(
    _ctx,
    phase: p.RuntimePhase.signedIn,
    connection: p.ConnectionState.online,
  );
  return bundle;
}

void main() {
  test(
    'six typed adapter boundaries exist and missing live contract fails closed',
    () async {
      final data = WorkerDataAdapters();
      final context = await data.access.restoreSession();
      expect(context, isA<c.ReadSuccess<c.WorkerSessionContext?>>());
      expect((context as c.ReadSuccess<c.WorkerSessionContext?>).value, isNull);
      expect(data.runtime.context, isNull);
      expect(
        await data.work.fetchAgenda(AgendaQuery()),
        isA<c.ReadFailure<AgendaView>>(),
      );
      expect(
        await data.finance.fetchDeposit(),
        isA<c.ReadFailure<DepositView>>(),
      );
      final unsupported = await data.access.signIn(
        phone: 'fake',
        password: 'fake',
      );
      expect(unsupported, isA<c.ReadFailure<c.WorkerSessionContext>>());
      expect((await data.access.signOut()).status, c.CommandStatus.rejected);
    },
  );

  test(
    'fixture transport maps agenda with selected session and server totals',
    () async {
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(
          200,
          _agenda([_row()], total: 13),
        );
      final data = await _started(t);
      final response = await data.work.fetchAgenda(AgendaQuery());
      expect(response, isA<c.ReadSuccess<AgendaView>>());
      final result = (response as c.ReadSuccess<AgendaView>).value;
      expect(result.items.total, 13);
      expect(result.items.items.single.scope.sessionId, 'visit-1');
      expect(result.items.items.single.endsAt, isNull);
      expect(
        result.items.items.single.operational.permits(
          c.WorkerAction.confirmWorkStart,
        ),
        isTrue,
      );
      expect(t.requests.single.operation, 'agenda');
      expect(t.requests.single.arguments['dateFrom'], isNull);
    },
  );

  test(
    'unknown wire actions disable lifecycle instead of enabling capability',
    () async {
      final row = _row();
      final operational = Map<String, Object?>.from(
        row['operationalContext']! as Map,
      );
      operational['allowedActions'] = ['confirm_work_start', 'admin_refund'];
      row['operationalContext'] = operational;
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([row]));
      final data = await _started(t);
      final result =
          await data.work.fetchAgenda(AgendaQuery())
              as c.ReadSuccess<AgendaView>;
      final capabilities = result.value.items.items.single.operational;
      expect(capabilities.executionCapability, isFalse);
      expect(capabilities.permits(c.WorkerAction.confirmWorkStart), isFalse);
      expect(capabilities.blockedReasons, contains('unavailable'));
    },
  );

  test(
    'malformed pagination and incorrect currency/money shape fail closed',
    () async {
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, {
          ..._agenda([_row()]),
          'meta': {'page': 1, 'lastPage': 1, 'total': '1'},
        });
      final data = await _started(t);
      final result = await data.work.fetchAgenda(AgendaQuery());
      expect(result, isA<c.ReadFailure<AgendaView>>());
      expect(
        (result as c.ReadFailure<AgendaView>).failure.reasonCode,
        'wire_contract_unavailable',
      );
      t.reads['earning'] = const WorkerWireResponse(200, {
        'key': 'session_assignment:1',
        'scope': {'bookingId': 'b-20'},
        'completedDate': '2026-10-23',
        'currency': 'SYP',
        'authoritativeAmount': {'decimal': 0.0, 'currency': 'SYP'},
        'reconciliationState': 'unknown',
        'frozenBreakdown': {},
      });
      final wrong = await data.finance.fetchEarning('session_assignment:1');
      expect(wrong, isA<c.ReadFailure<EarningEntryView>>());
    },
  );

  test(
    'nullable earning allocation remains null and source identity is preserved',
    () async {
      final t = _FakeTransport()
        ..reads['earning'] = const WorkerWireResponse(200, {
          'key': 'session_assignment:assigned-1',
          'scope': {
            'bookingId': 'b-20',
            'sessionId': 'visit-1',
            'assignmentId': 'assigned-1',
          },
          'completedDate': '2026-10-23',
          'currency': 'SYP',
          'authoritativeAmount': null,
          'reconciliationState': 'unreconciled',
          'frozenBreakdown': {},
        });
      final data = await _started(t);
      final response =
          await data.finance.fetchEarning('session_assignment:assigned-1')
              as c.ReadSuccess<EarningEntryView>;
      expect(response.value.key, 'session_assignment:assigned-1');
      expect(response.value.authoritativeAmount, isNull);
      expect(response.value.scope.sessionId, 'visit-1');
      final before = t.requests.length;
      final invalid = await data.finance.fetchEarning('unqualified-id');
      expect(invalid, isA<c.ReadFailure<EarningEntryView>>());
      expect(t.requests.length, before);
    },
  );

  test(
    '24-hour offline cache stores strict allowlist and disables actions',
    () async {
      final storage = MemoryWorkSummaryStorage();
      var clock = DateTime.utc(2026, 10, 23, 6);
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final data = await _started(t, storage: storage, clock: () => clock);
      expect(
        await data.work.fetchAgenda(_datedAgenda()),
        isA<c.ReadSuccess<AgendaView>>(),
      );
      final serialized = (await storage.read((await storage.keys()).single))!;
      for (final secret in [
        'never-store-phone',
        'never-store-address',
        'Private building',
        'latitude',
        'longitude',
        '999.98',
        'never-store-token',
        'never-store-otp',
        'never-store-dispute',
        'financial',
        'earnings',
        'customerPhone',
      ]) {
        expect(
          serialized,
          isNot(contains(secret)),
          reason: 'cache leaked $secret',
        );
      }
      data.runtime.updateConnection(p.ConnectionState.offline);
      clock = clock.add(const Duration(hours: 23));
      final offline =
          await data.work.fetchAgenda(_datedAgenda())
              as c.ReadSuccess<AgendaView>;
      expect(offline.freshness, c.ReadFreshness.offline);
      expect(
        offline.value.items.items.single.operational.allowedActions,
        isEmpty,
      );
      expect(
        offline.value.items.items.single.operational.executionCapability,
        isFalse,
      );
      clock = clock.add(const Duration(hours: 1));
      expect(
        await data.work.fetchAgenda(_datedAgenda()),
        isA<c.ReadFailure<AgendaView>>(),
      );
      expect(await storage.keys(), isEmpty);
    },
  );

  test(
    'mixed assigned and discoverable response invalidates prior cache and totals',
    () async {
      final storage = MemoryWorkSummaryStorage();
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(
          200,
          _agenda([_row()], total: 1),
        );
      final data = await _started(t, storage: storage);
      await data.work.fetchAgenda(_datedAgenda());
      expect((await storage.keys()).length, 1);
      t.reads['agenda'] = WorkerWireResponse(
        200,
        _agenda([
          _row(),
          _row(
            bookingId: 'offer',
            session: 'offer-visit',
            assignment: 'none',
            assignmentStatus: 'unassigned',
          ),
        ], total: 2),
      );
      await data.work.fetchAgenda(_datedAgenda());
      expect(await storage.keys(), isEmpty);
      data.runtime.updateConnection(p.ConnectionState.offline);
      expect(
        await data.work.fetchAgenda(_datedAgenda()),
        isA<c.ReadFailure<AgendaView>>(),
      );
    },
  );

  test(
    'generation switching and identity replacement always purge cached agenda',
    () async {
      final storage = MemoryWorkSummaryStorage();
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final data = await _started(t, storage: storage);
      await data.work.fetchAgenda(_datedAgenda());
      await data.runtime.replaceIdentity(
        c.WorkerSessionContext(
          userId: 'u-test',
          workerId: 'w-test',
          generation: 'gen-two',
        ),
        phase: p.RuntimePhase.signedIn,
        connection: p.ConnectionState.offline,
      );
      expect(await storage.keys(), isEmpty);
      expect(
        await data.work.fetchAgenda(_datedAgenda()),
        isA<c.ReadFailure<AgendaView>>(),
      );
      await data.runtime.purgeSessionData();
      expect(data.runtime.context, isNull);
    },
  );

  test(
    'late storage write after logout cannot resurrect an old generation',
    () async {
      final storage = _DelayedStorage();
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final data = await _started(t, storage: storage);
      final pending = data.work.fetchAgenda(_datedAgenda());
      // Prove the old write is suspended after identity validation.
      await storage.started.future;
      await data.runtime.purgeSessionData();
      storage.release.complete();
      final stale = await pending;
      expect(stale, isA<c.ReadFailure<AgendaView>>());
      expect(
        (stale as c.ReadFailure<AgendaView>).failure.kind,
        c.FailureKind.unauthenticated,
      );
      expect(await storage.keys(), isEmpty);
      expect(data.runtime.context, isNull);
    },
  );

  test(
    'delayed agenda write cannot return A records after B takes over',
    () async {
      final storage = _DelayedStorage();
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final bundle = await _started(t, storage: storage);
      final pending = bundle.work.fetchAgenda(_datedAgenda());
      await storage.started.future;
      await bundle.runtime.replaceIdentity(
        c.WorkerSessionContext(
          userId: 'u-new',
          workerId: 'w-new',
          generation: 'gen-new',
        ),
        phase: p.RuntimePhase.signedIn,
        connection: p.ConnectionState.online,
      );
      storage.release.complete();
      final result = await pending;
      expect(result, isA<c.ReadFailure<AgendaView>>());
      expect(
        (result as c.ReadFailure<AgendaView>).failure.kind,
        c.FailureKind.unauthenticated,
      );
      expect(await storage.keys(), isEmpty);
      expect(bundle.runtime.context?.userId, 'u-new');
    },
  );

  test(
    'overlapping login/login cleanup leaves only the latest identity',
    () async {
      final storage = _DelayedKeysStorage()..blockNextKeys = false;
      final transport = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final bundle = await _started(transport, storage: storage);
      await bundle.work.fetchAgenda(_datedAgenda());
      expect((await storage.keys()).length, 1);
      final events = StreamController<WorkerRealtimeNotice>.broadcast(
        sync: true,
      );
      bundle.runtime.bindEvents(events.stream);
      final seen = <c.DomainInvalidation>[];
      final sub = bundle.runtime.invalidations.listen(seen.add);
      storage.blockNextKeys = true;
      final first = bundle.runtime.replaceIdentity(
        _ctx,
        phase: p.RuntimePhase.signedIn,
        connection: p.ConnectionState.online,
      );
      await storage.started.future;
      final newer = c.WorkerSessionContext(
        userId: 'u-new',
        workerId: 'w-new',
        generation: 'gen-new',
      );
      final second = bundle.runtime.replaceIdentity(
        newer,
        phase: p.RuntimePhase.signedIn,
        connection: p.ConnectionState.online,
      );
      expect(bundle.runtime.context, isNull);
      storage.release.complete();
      await Future.wait([first, second]);
      expect(bundle.runtime.context?.userId, 'u-new');
      expect(bundle.runtime.context?.workerId, 'w-new');
      expect(bundle.runtime.context?.generation, 'gen-new');
      expect(bundle.runtime.phase, p.RuntimePhase.signedIn);
      expect(await storage.keys(), isEmpty);
      events.add(
        const WorkerRealtimeNotice(
          name: 'CleaningBookingCreated',
          userId: 'u-test',
          workerId: 'w-test',
          generation: 'gen-one',
          eventId: 'old',
        ),
      );
      events.add(
        const WorkerRealtimeNotice(
          name: 'CleaningBookingCreated',
          userId: 'u-new',
          workerId: 'w-new',
          generation: 'gen-new',
          eventId: 'new',
        ),
      );
      expect(seen.length, 1);
      expect(seen.single.generation, 'gen-new');
      await sub.cancel();
      await events.close();
      await bundle.runtime.dispose();
    },
  );

  test('overlapping login/logout cannot resurrect a revoked session', () async {
    final storage = _DelayedKeysStorage()..blockNextKeys = false;
    final transport = _FakeTransport()
      ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
    final bundle = await _started(transport, storage: storage);
    await bundle.work.fetchAgenda(_datedAgenda());
    expect((await storage.keys()).length, 1);
    storage.blockNextKeys = true;
    final login = bundle.runtime.replaceIdentity(
      _ctx,
      phase: p.RuntimePhase.signedIn,
      connection: p.ConnectionState.online,
    );
    await storage.started.future;
    final logout = bundle.runtime.purgeSessionData();
    storage.release.complete();
    await Future.wait([login, logout]);
    expect(bundle.runtime.context, isNull);
    expect(bundle.runtime.phase, p.RuntimePhase.revoked);
    expect(bundle.runtime.connection, p.ConnectionState.offline);
    expect(await storage.keys(), isEmpty);
  });

  test(
    'fetchToday rejects mixed A agenda and B readiness across a switch',
    () async {
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final readiness = Completer<WorkerWireResponse>();
      final readinessStarted = Completer<void>();
      t.pendingReads['readiness'] = readiness;
      t.readStarted['readiness'] = readinessStarted;
      final bundle = await _started(t);
      final pending = bundle.work.fetchToday();
      await readinessStarted.future;
      await bundle.runtime.replaceIdentity(
        c.WorkerSessionContext(
          userId: 'u-other',
          workerId: 'w-other',
          generation: 'gen-two',
        ),
        phase: p.RuntimePhase.signedIn,
        connection: p.ConnectionState.online,
      );
      readiness.complete(WorkerWireResponse(200, _readinessWire()));
      final result = await pending;
      expect(result, isA<c.ReadFailure<TodayView>>());
      expect(
        (result as c.ReadFailure<TodayView>).failure.kind,
        c.FailureKind.unauthenticated,
      );
    },
  );

  test('fetchToday rejects agenda when cache scope is invalidated during readiness read', () async {
    var agendaCalls = 0;
    final t = _FakeTransport();
    t.readHandlers['agenda'] = (_) {
      agendaCalls++;
      return agendaCalls == 1
          ? WorkerWireResponse(200, _agenda([_row()]))
          : const WorkerWireResponse(403, null);
    };
    final readiness = Completer<WorkerWireResponse>();
    final readinessStarted = Completer<void>();
    t.pendingReads['readiness'] = readiness;
    t.readStarted['readiness'] = readinessStarted;
    final bundle = await _started(t);

    final pendingToday = bundle.work.fetchToday();
    await readinessStarted.future;
    final denial = await bundle.work.fetchAgenda(_datedAgenda());
    expect(denial, isA<c.ReadFailure<AgendaView>>());
    expect((denial as c.ReadFailure<AgendaView>).failure.kind,
        c.FailureKind.forbidden);
    readiness.complete(WorkerWireResponse(200, _readinessWire()));

    final today = await pendingToday;
    expect(today, isA<c.ReadFailure<TodayView>>());
    expect((today as c.ReadFailure<TodayView>).failure.reasonCode,
        'scope_changed');
  });

  test(
    'offline implicit current-week never serves a Sunday record on Monday',
    () async {
      final storage = MemoryWorkSummaryStorage();
      var clock = DateTime.utc(2026, 10, 25, 20);
      final sunday = _row()..['scheduledDate'] = '2026-10-25';
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([sunday]));
      final bundle = await _started(t, storage: storage, clock: () => clock);
      expect(
        await bundle.work.fetchAgenda(AgendaQuery()),
        isA<c.ReadSuccess<AgendaView>>(),
      );
      expect(await storage.keys(), isEmpty);
      clock = DateTime.utc(2026, 10, 26, 8);
      bundle.runtime.updateConnection(p.ConnectionState.offline);
      expect(
        await bundle.work.fetchAgenda(AgendaQuery()),
        isA<c.ReadFailure<AgendaView>>(),
      );
      expect(await storage.keys(), isEmpty);
    },
  );

  test(
    'delayed cached read cannot survive purge followed by fresh write',
    () async {
      final storage = _DelayedReadStorage();
      final cache = ScopedWorkSummaryCache(
        storage: storage,
        currentIdentity: () => _ctx,
        isAuthenticated: () => true,
      );
      final query = _datedAgenda().key;
      await cache.writeAgenda(
        _ctx,
        query,
        WorkerWireMappers.agenda(_agenda([_row()])),
        expectedRevision: cache.revision,
      );
      storage.blockNextRead = true;
      final stale = cache.readAgenda(
        _ctx,
        query,
        freshness: c.ReadFreshness.offline,
      );
      await storage.started.future;
      await cache.purgeAll();
      await cache.writeAgenda(
        _ctx,
        query,
        WorkerWireMappers.agenda(_agenda([_row(session: 'fresh-visit')])),
        expectedRevision: cache.revision,
      );
      storage.release.complete();
      expect(await stale, isNull);
      final fresh = await cache.readAgenda(
        _ctx,
        query,
        freshness: c.ReadFreshness.offline,
      );
      expect(fresh?.value.items.items.single.scope.sessionId, 'fresh-visit');
    },
  );

  test('old V1 cache namespace and document are excluded by the V2 reader', () async {
    final storage = MemoryWorkSummaryStorage();
    final cache = ScopedWorkSummaryCache(
      storage: storage,
      currentIdentity: () => _ctx,
      isAuthenticated: () => true,
    );
    final query = _datedAgenda().key;
    final oldKey = jsonEncode([
      'worker-work-summary',
      'V1',
      _ctx.userId,
      _ctx.workerId,
      _ctx.generation,
      query,
    ]);
    await storage.write(oldKey, jsonEncode({
      'version': 'V1',
      'identity': [_ctx.userId, _ctx.workerId, _ctx.generation],
      'query': query,
      'savedAt': DateTime.utc(2026, 10, 23).toIso8601String(),
      'page': 1,
      'lastPage': 1,
      'total': 1,
      'activeVisits': 1,
      'rows': <Object?>[],
    }));
    expect(ScopedWorkSummaryCache.contractVersion, 'V2');
    expect(
      await cache.readAgenda(
        _ctx,
        query,
        freshness: c.ReadFreshness.offline,
      ),
      isNull,
    );
    expect(await storage.read(oldKey), isNotNull);
  });

  test('fresh unrelated write cannot resurrect a revoked row during scoped purge', () async {
    final storage = _DelayedKeysStorage()..blockNextKeys = false;
    final cache = ScopedWorkSummaryCache(
      storage: storage,
      currentIdentity: () => _ctx,
      isAuthenticated: () => true,
    );
    final queryA = _datedAgenda().key;
    final queryB = AgendaQuery(
      dates: DateRange(from: '2026-10-24', to: '2026-10-24'),
    ).key;
    await cache.writeAgenda(
      _ctx,
      queryA,
      WorkerWireMappers.agenda(_agenda([_row()])),
      expectedRevision: cache.revision,
    );

    storage.blockNextKeys = true;
    final purge = cache.purgeScope(_scope);
    await storage.started.future;
    await cache.writeAgenda(
      _ctx,
      queryB,
      WorkerWireMappers.agenda(_agenda([
        _row(bookingId: 'b-other', session: 'visit-other', assignment: 'assigned-other'),
      ])),
      expectedRevision: cache.revision,
    );
    expect(
      await cache.readAgenda(
        _ctx,
        queryA,
        freshness: c.ReadFreshness.offline,
      ),
      isNull,
    );

    storage.release.complete();
    await purge;
    expect(
      await cache.readAgenda(
        _ctx,
        queryA,
        freshness: c.ReadFreshness.offline,
      ),
      isNull,
    );
    final freshB = await cache.readAgenda(
      _ctx,
      queryB,
      freshness: c.ReadFreshness.offline,
    );
    expect(freshB?.value.items.items.single.scope.bookingId, 'b-other');
  });

  test(
    'same-key writes are ordered and an old write cannot replace a new row',
    () async {
      final storage = _DelayedStorage();
      final cache = ScopedWorkSummaryCache(
        storage: storage,
        currentIdentity: () => _ctx,
        isAuthenticated: () => true,
      );
      final query = _datedAgenda().key;
      final original = cache.writeAgenda(
        _ctx,
        query,
        WorkerWireMappers.agenda(_agenda([_row()])),
        expectedRevision: cache.revision,
      );
      await storage.started.future;
      final newer = cache.writeAgenda(
        _ctx,
        query,
        WorkerWireMappers.agenda(_agenda([_row(session: 'newer-visit')])),
        expectedRevision: cache.revision,
      );
      storage.release.complete();
      await Future.wait([original, newer]);
      final latest = await cache.readAgenda(
        _ctx,
        query,
        freshness: c.ReadFreshness.offline,
      );
      expect(latest?.value.items.items.single.scope.sessionId, 'newer-visit');
    },
  );

  test(
    'worker ID and user ID partitions cannot read another identity cache',
    () async {
      c.WorkerSessionContext current = _ctx;
      final cache = ScopedWorkSummaryCache(
        storage: MemoryWorkSummaryStorage(),
        currentIdentity: () => current,
        isAuthenticated: () => true,
      );
      final source = AgendaView(
        items: c.Page(
          items: [
            AgendaItemView(
              key: 'k',
              scope: _scope,
              scheduledDate: '2026-10-23',
              status: 'active',
              ownAssignmentStatus: 'assigned',
              work: const WorkSummary(label: 'Cleaning', type: 'regular'),
              operational: c.OperationalContext(
                executionOwner: c.ExecutionOwner.worker,
                executionCapability: true,
                allowedActions: {c.WorkerAction.view},
                canRecordAttendance: true,
              ),
            ),
          ],
          page: 1,
          lastPage: 1,
          total: 1,
        ),
        timezone: 'Asia/Damascus',
        activeVisits: 1,
      );
      await cache.writeAgenda(
        current,
        'date-query',
        source,
        expectedRevision: cache.revision,
      );
      expect(
        await cache.readAgenda(
          current,
          'date-query',
          freshness: c.ReadFreshness.stale,
        ),
        isNotNull,
      );
      final first = current;
      current = c.WorkerSessionContext(
        userId: first.userId,
        workerId: 'other-worker',
        generation: first.generation,
      );
      expect(
        await cache.readAgenda(
          current,
          'date-query',
          freshness: c.ReadFreshness.offline,
        ),
        isNull,
      );
      current = c.WorkerSessionContext(
        userId: 'other-user',
        workerId: first.workerId,
        generation: first.generation,
      );
      expect(
        await cache.readAgenda(
          current,
          'date-query',
          freshness: c.ReadFreshness.offline,
        ),
        isNull,
      );
      current = first;
      expect(
        await cache.readAgenda(
          current,
          'other-query',
          freshness: c.ReadFreshness.offline,
        ),
        isNull,
      );
    },
  );

  test(
    '401 purges cached identity, 403 scoped denial removes persisted scope',
    () async {
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final storage = MemoryWorkSummaryStorage();
      final data = await _started(t, storage: storage);
      await data.work.fetchAgenda(_datedAgenda());
      t.reads['mission'] = const WorkerWireResponse(403, null);
      final denied = await data.mission.fetchMission(_scope);
      expect(denied, isA<c.ReadFailure<MissionView>>());
      expect(await storage.keys(), isEmpty);
      t.reads['mission'] = const WorkerWireResponse(401, null);
      await data.mission.fetchMission(_scope);
      expect(data.runtime.context, isNull);
      expect(data.runtime.phase, p.RuntimePhase.revoked);
    },
  );

  test(
    'agenda 403 purges entire worker cache and forbids offline fallback',
    () async {
      final storage = MemoryWorkSummaryStorage();
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final bundle = await _started(t, storage: storage);
      expect(
        await bundle.work.fetchAgenda(_datedAgenda()),
        isA<c.ReadSuccess<AgendaView>>(),
      );
      expect((await storage.keys()).length, 1);
      t.reads['agenda'] = const WorkerWireResponse(403, null);
      final forbidden = await bundle.work.fetchAgenda(_datedAgenda());
      expect(forbidden, isA<c.ReadFailure<AgendaView>>());
      expect(
        (forbidden as c.ReadFailure<AgendaView>).failure.kind,
        c.FailureKind.forbidden,
      );
      expect(await storage.keys(), isEmpty);
      bundle.runtime.updateConnection(p.ConnectionState.offline);
      expect(
        await bundle.work.fetchAgenda(_datedAgenda()),
        isA<c.ReadFailure<AgendaView>>(),
      );
    },
  );

  test(
    'agenda 403 also prevents a delayed authorized write resurrecting rows',
    () async {
      final storage = _DelayedStorage();
      final t = _FakeTransport()
        ..reads['agenda'] = WorkerWireResponse(200, _agenda([_row()]));
      final bundle = await _started(t, storage: storage);
      final pending = bundle.work.fetchAgenda(_datedAgenda());
      await storage.started.future;
      t.reads['agenda'] = const WorkerWireResponse(403, null);
      final forbidden = await bundle.work.fetchAgenda(_datedAgenda());
      expect(
        (forbidden as c.ReadFailure<AgendaView>).failure.kind,
        c.FailureKind.forbidden,
      );
      storage.release.complete();
      await pending;
      expect(await storage.keys(), isEmpty);
      bundle.runtime.updateConnection(p.ConnectionState.offline);
      expect(
        await bundle.work.fetchAgenda(_datedAgenda()),
        isA<c.ReadFailure<AgendaView>>(),
      );
    },
  );

  test(
    'older 200 agenda response arriving after 403 cannot publish old rows',
    () async {
      final t = _FakeTransport();
      final pendingResponse = Completer<WorkerWireResponse>();
      final started = Completer<void>();
      t.pendingReads['agenda'] = pendingResponse;
      t.readStarted['agenda'] = started;
      final bundle = await _started(t);
      final oldRead = bundle.work.fetchAgenda(_datedAgenda());
      await started.future;
      t.pendingReads.remove('agenda');
      t.reads['agenda'] = const WorkerWireResponse(403, null);
      final denied = await bundle.work.fetchAgenda(_datedAgenda());
      expect(
        (denied as c.ReadFailure<AgendaView>).failure.kind,
        c.FailureKind.forbidden,
      );
      pendingResponse.complete(WorkerWireResponse(200, _agenda([_row()])));
      expect(await oldRead, isA<c.ReadFailure<AgendaView>>());
    },
  );

  test(
    'mission rejects wrong booking, selected visit and assignment IDs',
    () async {
      final t = _FakeTransport();
      final bundle = await _started(t);
      for (final wrong in <Map<String, Object?>>[
        {
          'bookingId': 'other-booking',
          'sessionId': 'visit-1',
          'assignmentId': 'assigned-1',
        },
        {
          'bookingId': 'b-20',
          'sessionId': 'other-visit',
          'assignmentId': 'assigned-1',
        },
        {
          'bookingId': 'b-20',
          'sessionId': 'visit-1',
          'assignmentId': 'other-assignment',
        },
      ]) {
        final wire = _missionWire()..['scope'] = wrong;
        t.reads['mission'] = WorkerWireResponse(200, wire);
        final mission = await bundle.mission.fetchMission(_scope);
        expect(mission, isA<c.ReadFailure<MissionView>>());
        expect(
          (mission as c.ReadFailure<MissionView>).failure.reasonCode,
          'wire_contract_unavailable',
        );
        t.reads['visit_scope'] = WorkerWireResponse(200, wire);
        expect(
          await bundle.mission.fetchVisitScope(_scope),
          isA<c.ReadFailure<MissionView>>(),
        );
      }
      t.reads['mission'] = WorkerWireResponse(200, _missionWire());
      expect(
        await bundle.mission.fetchMission(_scope),
        isA<c.ReadSuccess<MissionView>>(),
      );
    },
  );

  test(
    'selected inventory and decision scopes cannot escape requested visit',
    () async {
      final t = _FakeTransport()
        ..reads['inventory'] = const WorkerWireResponse(200, {
          'scope': {
            'bookingId': 'b-20',
            'sessionId': 'another-visit',
            'assignmentId': 'assigned-1',
          },
          'items': [],
        })
        ..reads['decisions'] = const WorkerWireResponse(200, [
          {
            'requestId': 'change-x',
            'scope': {
              'bookingId': 'b-20',
              'sessionId': 'another-visit',
              'assignmentId': 'assigned-1',
            },
            'kind': 'schedule_change',
            'status': 'pending',
            'decisionActor': 'worker',
            'currentValues': {},
            'proposedValues': {},
            'pricedAmount': null,
          },
        ]);
      final bundle = await _started(t);
      expect(
        await bundle.mission.fetchInventory(_scope),
        isA<c.ReadFailure<InventoryView>>(),
      );
      expect(
        await bundle.mission.fetchDecisions(_scope),
        isA<c.ReadFailure<List<DecisionView>>>(),
      );
    },
  );

  test(
    'mission line identities carry exact visit scope and reject foreign nested lines',
    () async {
      final t = _FakeTransport();
      final bundle = await _started(t);
      final wire = _missionWire()
        ..['serviceLines'] = [
          {
            'scope': {
              'bookingId': 'b-20',
              'sessionId': 'visit-1',
              'assignmentId': 'assigned-1',
            },
            'lineId': 'line-7',
            'label': 'Window cleaning',
            'status': 'pending',
            'allowedActions': ['start_special_service'],
          },
        ];
      t.reads['mission'] = WorkerWireResponse(200, wire);
      final result = await bundle.mission.fetchMission(_scope);
      expect(result, isA<c.ReadSuccess<MissionView>>());
      final mission = (result as c.ReadSuccess<MissionView>).value;
      expect(mission.serviceLines.single.lineId, 'line-7');
      expect(mission.serviceLines.single.scope.sessionId, 'visit-1');
      final command = SpecialServiceStartCommand(
        mission.serviceLines.single.scope,
        lineId: mission.serviceLines.single.lineId,
      );
      t.writes['mission_start_special_service'] = const WorkerWireResponse(
        200,
        {},
      );
      expect(
        (await bundle.mission.submit(command)).status,
        c.CommandStatus.confirmed,
      );
      expect(t.requests.last.arguments['lineId'], 'line-7');

      final foreignWire = _missionWire()
        ..['serviceLines'] = [
          {
            'scope': {
              'bookingId': 'b-20',
              'sessionId': 'other-visit',
              'assignmentId': 'assigned-1',
            },
            'lineId': 'foreign-line',
            'label': 'Window cleaning',
            'status': 'pending',
            'allowedActions': ['start_special_service'],
          },
        ];
      t.reads['mission'] = WorkerWireResponse(200, foreignWire);
      expect(
        await bundle.mission.fetchMission(_scope),
        isA<c.ReadFailure<MissionView>>(),
      );
    },
  );

  test(
    'inventory command identity uses reservationId and missing identity disables custody actions',
    () async {
      final t = _FakeTransport();
      final bundle = await _started(t);
      t.reads['inventory'] = const WorkerWireResponse(200, {
        'scope': {
          'bookingId': 'b-20',
          'sessionId': 'visit-1',
          'assignmentId': 'assigned-1',
        },
        'items': [
          {
            'itemId': 'equipment-4',
            'reservationId': 'reservation-9',
            'name': 'Vacuum',
            'quantity': '1',
            'custodyState': 'issued',
            'allowedActions': ['acknowledge_equipment', 'return_equipment'],
          },
          {
            'itemId': 'equipment-5',
            'name': 'Mop',
            'quantity': '1',
            'custodyState': 'reserved',
            'allowedActions': ['acknowledge_equipment', 'return_equipment'],
          },
        ],
      });
      final result = await bundle.mission.fetchInventory(_scope);
      expect(result, isA<c.ReadSuccess<InventoryView>>());
      final items = (result as c.ReadSuccess<InventoryView>).value.items;
      expect(items.first.itemId, 'equipment-4');
      expect(items.first.reservationId, 'reservation-9');
      expect(items.last.reservationId, isNull);
      expect(
        items.last.allowedActions,
        isNot(contains(c.WorkerAction.acknowledgeEquipment)),
      );
      expect(
        items.last.allowedActions,
        isNot(contains(c.WorkerAction.returnEquipment)),
      );
      final command = AcknowledgeEquipmentCommand(
        _scope,
        reservationId: items.first.reservationId!,
      );
      t.writes['mission_acknowledge_equipment'] = const WorkerWireResponse(
        200,
        {},
      );
      expect(
        (await bundle.mission.submit(command)).status,
        c.CommandStatus.confirmed,
      );
      expect(t.requests.last.arguments['reservationId'], 'reservation-9');
      expect(t.requests.last.arguments['reservationId'], isNot('equipment-4'));
    },
  );

  test(
    'extension record family and optional minutes survive semantic command mapping',
    () async {
      final t = _FakeTransport();
      final bundle = await _started(t);
      t.reads['decisions'] = const WorkerWireResponse(200, [
        {
          'requestId': '42',
          'scope': {
            'bookingId': 'b-20',
            'sessionId': 'visit-1',
            'assignmentId': 'assigned-1',
          },
          'kind': 'extension',
          'extensionFamily': 'fixedTimeWarning',
          'status': 'pending',
          'decisionActor': 'worker',
          'currentValues': {},
          'proposedValues': {},
          'pricedAmount': null,
        },
        {
          'requestId': '42',
          'scope': {
            'bookingId': 'b-20',
            'sessionId': 'visit-1',
            'assignmentId': 'assigned-1',
          },
          'kind': 'extension',
          'extensionFamily': 'openTimeExtension',
          'status': 'pending',
          'decisionActor': 'worker',
          'currentValues': {},
          'proposedValues': {},
          'pricedAmount': null,
        },
        {
          'requestId': 'unknown-family',
          'scope': {
            'bookingId': 'b-20',
            'sessionId': 'visit-1',
            'assignmentId': 'assigned-1',
          },
          'kind': 'extension',
          'status': 'pending',
          'decisionActor': 'worker',
          'currentValues': {},
          'proposedValues': {},
          'pricedAmount': null,
        },
      ]);
      final result = await bundle.mission.fetchDecisions(_scope);
      expect(result, isA<c.ReadSuccess<List<DecisionView>>>());
      final decisions = (result as c.ReadSuccess<List<DecisionView>>).value;
      expect(
        decisions[0].extensionFamily,
        ExtensionRecordFamily.fixedTimeWarning,
      );
      expect(
        decisions[1].extensionFamily,
        ExtensionRecordFamily.openTimeExtension,
      );
      expect(decisions[2].extensionFamily, isNull);

      final fixed = ExtensionDecisionCommand(
        decisions[0].scope,
        extensionId: decisions[0].requestId,
        family: decisions[0].extensionFamily!,
        accept: true,
        additionalMinutes: 15,
      );
      final open = ExtensionDecisionCommand(
        decisions[1].scope,
        extensionId: decisions[1].requestId,
        family: decisions[1].extensionFamily!,
        accept: true,
      );
      t.writes['mission_accept_extension'] = const WorkerWireResponse(200, {});
      expect(
        (await bundle.mission.submit(fixed)).status,
        c.CommandStatus.confirmed,
      );
      final fixedArgs = Map<String, Object?>.from(t.requests.last.arguments);
      expect(
        (await bundle.mission.submit(open)).status,
        c.CommandStatus.confirmed,
      );
      final openArgs = Map<String, Object?>.from(t.requests.last.arguments);
      expect(fixedArgs['extensionId'], '42');
      expect(openArgs['extensionId'], '42');
      expect(fixedArgs['family'], 'fixedTimeWarning');
      expect(openArgs['family'], 'openTimeExtension');
      expect(fixedArgs['decision'], 'accepted');
      expect(fixedArgs['additionalMinutes'], 15);
      expect(openArgs.containsKey('additionalMinutes'), isFalse);

      // A missing family remains null at the read boundary, so a consumer has
      // no family value from which to construct the required decision command.
      expect(decisions[2].extensionFamily, isNull);
    },
  );

  test('wrong offer booking, earning key and dispute ID fail closed', () async {
    final t = _FakeTransport()
      ..reads['offer'] = const WorkerWireResponse(200, {
        'bookingId': 'b-other',
        'bookingType': 'regular',
        'discoverable': true,
        'eligible': true,
        'work': {'label': 'Cleaning', 'type': 'regular'},
        'acceptanceModes': [],
        'visitChoices': [],
        'pricingIsFinal': false,
        'workerAmount': null,
      })
      ..reads['earning'] = const WorkerWireResponse(200, {
        'key': 'booking_assignment:other',
        'scope': {'bookingId': 'b-20', 'assignmentId': 'assigned-1'},
        'completedDate': '2026-10-23',
        'currency': 'SYP',
        'authoritativeAmount': null,
        'reconciliationState': 'unreconciled',
        'frozenBreakdown': {},
      })
      ..reads['dispute'] = const WorkerWireResponse(200, {
        'id': 'dispute-other',
        'scope': {'bookingId': 'b-20'},
        'status': 'open',
        'statusHistory': [],
        'messages': [],
        'canReply': true,
      });
    final bundle = await _started(t);
    final offer = await bundle.work.fetchOffer('b-20');
    expect(offer, isA<c.ReadFailure<OfferView>>());
    expect(
      (offer as c.ReadFailure<OfferView>).failure.reasonCode,
      'wire_contract_unavailable',
    );
    final earning = await bundle.finance.fetchEarning(
      'session_assignment:assigned-1',
    );
    expect(earning, isA<c.ReadFailure<EarningEntryView>>());
    expect(
      (earning as c.ReadFailure<EarningEntryView>).failure.reasonCode,
      'wire_contract_unavailable',
    );
    final dispute = await bundle.finance.fetchDispute('dispute-a');
    expect(dispute, isA<c.ReadFailure<DisputeView>>());
    expect(
      (dispute as c.ReadFailure<DisputeView>).failure.reasonCode,
      'wire_contract_unavailable',
    );
  });

  test('profile response must belong to the authenticated worker', () async {
    final t = _FakeTransport()
      ..reads['profile'] = WorkerWireResponse(
        200,
        _profileWire(workerId: 'w-other'),
      );
    final bundle = await _started(t);
    final wrong = await bundle.access.fetchProfile();
    expect(wrong, isA<c.ReadFailure<WorkerProfileView>>());
    expect(
      (wrong as c.ReadFailure<WorkerProfileView>).failure.reasonCode,
      'wire_contract_unavailable',
    );

    t.reads['profile'] = WorkerWireResponse(200, _profileWire());
    final matching = await bundle.access.fetchProfile();
    expect(matching, isA<c.ReadSuccess<WorkerProfileView>>());
    expect(
      (matching as c.ReadSuccess<WorkerProfileView>).value.workerId,
      'w-test',
    );
  });

  test('a pre-command GET cannot resolve an uncertain mission write', () async {
    final t = _FakeTransport();
    final oldMission = Completer<WorkerWireResponse>();
    final started = Completer<void>();
    t.pendingReads['mission'] = oldMission;
    t.readStarted['mission'] = started;
    final bundle = await _started(t);
    final oldRead = bundle.mission.fetchMission(_scope);
    await started.future;

    t.writeFault = const WorkerTransportFault(WorkerTransportFaultKind.timeout);
    final command = SimpleMissionCommand(
      _scope,
      SimpleMissionAction.startTravel,
    );
    expect(
      (await bundle.mission.submit(command)).status,
      c.CommandStatus.outcomeUnknown,
    );

    t.pendingReads.remove('mission');
    oldMission.complete(WorkerWireResponse(200, _missionWire()));
    expect(await oldRead, isA<c.ReadSuccess<MissionView>>());
    expect(
      (await bundle.mission.submit(command)).reasonCode,
      'refetch_required',
    );

    t.writeFault = null;
    t.reads['mission'] = WorkerWireResponse(200, _missionWire());
    expect(
      await bundle.mission.fetchMission(_scope),
      isA<c.ReadSuccess<MissionView>>(),
    );
    t.writes['mission_start_travel'] = const WorkerWireResponse(200, {});
    expect(
      (await bundle.mission.submit(command)).status,
      c.CommandStatus.confirmed,
    );
  });

  test('uncertain mission writes require matching domain reads and SOS stays locked', () async {
    final t = _FakeTransport();
    final bundle = await _started(t);
    final equipment = AcknowledgeEquipmentCommand(
      _scope,
      reservationId: 'reservation-9',
    );
    t.writeFault = const WorkerTransportFault(WorkerTransportFaultKind.timeout);
    expect((await bundle.mission.submit(equipment)).status,
        c.CommandStatus.outcomeUnknown);

    t.writeFault = null;
    t.reads['mission'] = WorkerWireResponse(200, _missionWire());
    expect(await bundle.mission.fetchMission(_scope),
        isA<c.ReadSuccess<MissionView>>());
    expect((await bundle.mission.submit(equipment)).reasonCode,
        'refetch_required');

    t.reads['inventory'] = const WorkerWireResponse(200, {
      'scope': {
        'bookingId': 'b-20',
        'sessionId': 'visit-1',
        'assignmentId': 'assigned-1',
      },
      'items': [],
    });
    expect(await bundle.mission.fetchInventory(_scope),
        isA<c.ReadSuccess<InventoryView>>());
    t.writes['mission_acknowledge_equipment'] =
        const WorkerWireResponse(200, {});
    expect((await bundle.mission.submit(equipment)).status,
        c.CommandStatus.confirmed);

    final extension = ExtensionDecisionCommand(
      _scope,
      extensionId: 'warning-9',
      family: ExtensionRecordFamily.fixedTimeWarning,
      accept: true,
      additionalMinutes: 15,
    );
    t.writeFault = const WorkerTransportFault(WorkerTransportFaultKind.timeout);
    expect((await bundle.mission.submit(extension)).status,
        c.CommandStatus.outcomeUnknown);
    t.writeFault = null;
    expect(await bundle.mission.fetchMission(_scope),
        isA<c.ReadSuccess<MissionView>>());
    expect((await bundle.mission.submit(extension)).reasonCode,
        'refetch_required');
    t.reads['decisions'] = const WorkerWireResponse(200, []);
    expect(await bundle.mission.fetchDecisions(_scope),
        isA<c.ReadSuccess<List<DecisionView>>>());
    t.writes['mission_accept_extension'] = const WorkerWireResponse(200, {});
    expect((await bundle.mission.submit(extension)).status,
        c.CommandStatus.confirmed);

    t.writeFault = const WorkerTransportFault(WorkerTransportFaultKind.timeout);
    final sosDraft = const SosDraft(reason: 'safety concern');
    expect((await bundle.communications.sendSos(_scope, sosDraft)).status,
        c.CommandStatus.outcomeUnknown);
    t.writeFault = null;
    expect(await bundle.mission.fetchMission(_scope),
        isA<c.ReadSuccess<MissionView>>());
    expect((await bundle.communications.sendSos(_scope, sosDraft)).reasonCode,
        'refetch_required');
  });

  test(
    'older private detail success cannot escape after newer scope denial',
    () async {
      final t = _FakeTransport();
      final olderResponse = Completer<WorkerWireResponse>();
      final started = Completer<void>();
      t.pendingReads['mission'] = olderResponse;
      t.readStarted['mission'] = started;
      final bundle = await _started(t);
      final oldRead = bundle.mission.fetchMission(_scope);
      await started.future;

      t.pendingReads.remove('mission');
      t.reads['mission'] = const WorkerWireResponse(403, null);
      final denied = await bundle.mission.fetchMission(_scope);
      expect(denied, isA<c.ReadFailure<MissionView>>());

      olderResponse.complete(WorkerWireResponse(200, _missionWire()));
      final oldResult = await oldRead;
      expect(oldResult, isA<c.ReadFailure<MissionView>>());
      expect(
        (oldResult as c.ReadFailure<MissionView>).failure.kind,
        c.FailureKind.forbidden,
      );
    },
  );

  test(
    'older dispute messages cannot escape after newer entity denial',
    () async {
      final t = _FakeTransport();
      final olderResponse = Completer<WorkerWireResponse>();
      final started = Completer<void>();
      t.pendingReads['dispute'] = olderResponse;
      t.readStarted['dispute'] = started;
      final bundle = await _started(t);
      final oldRead = bundle.finance.fetchDispute('dispute-a');
      await started.future;

      t.pendingReads.remove('dispute');
      t.reads['dispute'] = const WorkerWireResponse(403, null);
      expect(
        await bundle.finance.fetchDispute('dispute-a'),
        isA<c.ReadFailure<DisputeView>>(),
      );

      olderResponse.complete(
        const WorkerWireResponse(200, {
          'id': 'dispute-a',
          'scope': {'bookingId': 'b-20'},
          'status': 'open',
          'statusHistory': [],
          'messages': [
            {
              'id': 'message-1',
              'sentAt': '2026-10-23T06:00:00Z',
              'body': 'private message must not escape',
              'senderLabel': 'Worker',
            },
          ],
          'canReply': true,
        }),
      );
      final oldResult = await oldRead;
      expect(oldResult, isA<c.ReadFailure<DisputeView>>());
      expect(
        (oldResult as c.ReadFailure<DisputeView>).failure.kind,
        c.FailureKind.forbidden,
      );
    },
  );

  test('profile mutations require their matching recovery read', () async {
    final t = _FakeTransport()
      ..reads['work_areas'] = const WorkerWireResponse(200, ['area-1'])
      ..reads['start_location'] = const WorkerWireResponse(200, null);
    final bundle = await _started(t);
    t.writeFault = const WorkerTransportFault(WorkerTransportFaultKind.timeout);
    const draft = StartLocationDraft(source: 'saved', savedLocationId: 'loc-1');
    expect(
      (await bundle.access.saveStartLocation(draft)).status,
      c.CommandStatus.outcomeUnknown,
    );

    expect(
      await bundle.access.fetchWorkAreas(),
      isA<c.ReadSuccess<List<String>>>(),
    );
    expect(
      (await bundle.access.saveStartLocation(draft)).reasonCode,
      'refetch_required',
    );

    expect(
      await bundle.access.fetchStartLocation(),
      isA<c.ReadSuccess<StartLocationDraft?>>(),
    );
    t.writeFault = null;
    t.writes['save_start_location'] = const WorkerWireResponse(200, {});
    expect(
      (await bundle.access.saveStartLocation(draft)).status,
      c.CommandStatus.confirmed,
    );
  });

  test(
    'notification lock clears after a complete bounded multipage refresh',
    () async {
      final t = _FakeTransport();
      t.readHandlers['notifications'] = (request) {
        final page = request.arguments['page'] as int;
        return WorkerWireResponse(200, {
          'data': [
            {
              'id': 'notice-$page',
              'title': 'Notice $page',
              'body': 'fixture body',
              'sentAt': '2026-10-23T06:00:00Z',
              'isRead': false,
            },
          ],
          'meta': {'page': page, 'lastPage': 2, 'total': 101},
        });
      };
      final bundle = await _started(t);
      t.writeFault = const WorkerTransportFault(
        WorkerTransportFaultKind.timeout,
      );
      expect(
        (await bundle.communications.markNotificationRead('notice-1')).status,
        c.CommandStatus.outcomeUnknown,
      );

      expect(
        await bundle.communications.fetchNotifications(
          NotificationQuery(
            page: PageQuery(page: 1, perPage: 100),
            unreadOnly: true,
          ),
        ),
        isA<c.ReadSuccess<c.Page<NotificationView>>>(),
      );
      expect(
        (await bundle.communications.markNotificationRead(
          'notice-1',
        )).reasonCode,
        'refetch_required',
      );

      expect(
        await bundle.communications.fetchNotifications(
          NotificationQuery(page: PageQuery(page: 1, perPage: 100)),
        ),
        isA<c.ReadSuccess<c.Page<NotificationView>>>(),
      );
      expect(t.requests.where((r) => r.operation == 'notifications').length, 3);
      t.writeFault = null;
      t.writes['mark_notification_read'] = const WorkerWireResponse(200, {});
      expect(
        (await bundle.communications.markNotificationRead('notice-1')).status,
        c.CommandStatus.confirmed,
      );
    },
  );

  test(
    'multipage notification recovery cannot publish old identity after logout',
    () async {
      final t = _FakeTransport();
      t.readHandlers['notifications'] = (request) => WorkerWireResponse(200, {
        'data': [
          {
            'id': 'notice-${request.arguments['page']}',
            'title': 'Notice',
            'body': 'private notification body',
            'sentAt': '2026-10-23T06:00:00Z',
            'isRead': false,
          },
        ],
        'meta': {
          'page': request.arguments['page'],
          'lastPage': 2,
          'total': 101,
        },
      });
      final pageTwo = Completer<WorkerWireResponse>();
      final pageTwoStarted = Completer<void>();
      t.pendingReadsByRequest['notifications:2'] = pageTwo;
      t.readStartedByRequest['notifications:2'] = pageTwoStarted;
      final bundle = await _started(t);
      t.writeFault = const WorkerTransportFault(
        WorkerTransportFaultKind.timeout,
      );
      await bundle.communications.markNotificationRead('notice-1');

      final pending = bundle.communications.fetchNotifications(
        NotificationQuery(page: PageQuery(page: 1, perPage: 100)),
      );
      await pageTwoStarted.future;
      await bundle.runtime.replaceIdentity(
        c.WorkerSessionContext(
          userId: 'u-next',
          workerId: 'w-next',
          generation: 'gen-next',
        ),
        phase: p.RuntimePhase.signedIn,
        connection: p.ConnectionState.online,
      );
      pageTwo.complete(
        WorkerWireResponse(200, {
          'data': [],
          'meta': {'page': 2, 'lastPage': 2, 'total': 101},
        }),
      );
      final result = await pending;
      expect(result, isA<c.ReadFailure<c.Page<NotificationView>>>());
      expect(
        (result as c.ReadFailure<c.Page<NotificationView>>).failure.kind,
        c.FailureKind.unauthenticated,
      );
    },
  );

  test(
    'notification multipage recovery propagates a later page denial',
    () async {
      final t = _FakeTransport();
      t.readHandlers['notifications'] = (request) {
        final page = request.arguments['page'] as int;
        if (page == 2) return const WorkerWireResponse(403, null);
        return const WorkerWireResponse(200, {
          'data': [],
          'meta': {'page': 1, 'lastPage': 2, 'total': 101},
        });
      };
      final bundle = await _started(t);
      t.writeFault = const WorkerTransportFault(
        WorkerTransportFaultKind.timeout,
      );
      await bundle.communications.markNotificationRead('notice-1');
      final result = await bundle.communications.fetchNotifications(
        NotificationQuery(page: PageQuery(page: 1, perPage: 100)),
      );
      expect(result, isA<c.ReadFailure<c.Page<NotificationView>>>());
      expect(
        (result as c.ReadFailure<c.Page<NotificationView>>).failure.kind,
        c.FailureKind.forbidden,
      );
      expect(
        (await bundle.communications.markNotificationRead(
          'notice-1',
        )).reasonCode,
        'refetch_required',
      );
    },
  );

  test(
    'timeout produces outcomeUnknown and read must resolve before retry',
    () async {
      final t = _FakeTransport()
        ..reads['mission'] = WorkerWireResponse(200, _missionWire());
      final data = await _started(t);
      final command = SimpleMissionCommand(
        _scope,
        SimpleMissionAction.startTravel,
      );
      t.writeFault = const WorkerTransportFault(
        WorkerTransportFaultKind.timeout,
      );
      expect(
        (await data.mission.submit(command)).status,
        c.CommandStatus.outcomeUnknown,
      );
      expect(
        (await data.mission.submit(command)).reasonCode,
        'refetch_required',
      );
      t.writeFault = null;
      t.writes['mission_start_travel'] = const WorkerWireResponse(200, {});
      expect(
        (await data.mission.submit(command)).reasonCode,
        'refetch_required',
      );
      final reloaded = await data.mission.fetchMission(_scope);
      expect(reloaded, isA<c.ReadSuccess<MissionView>>());
      expect(
        (await data.mission.submit(command)).status,
        c.CommandStatus.confirmed,
      );
      expect(
        t.requests.where((r) => r.operation == 'mission_start_travel').length,
        2,
      );
    },
  );

  test(
    '409 locks retry until same-scope refetch; 422 sanitizes fields',
    () async {
      final t = _FakeTransport()
        ..writes['post_dispute_message'] = const WorkerWireResponse(409, {
          'reason': 'private server diagnostic',
        });
      final data = await _started(t);
      expect(
        (await data.finance.postDisputeMessage(
          'dispute-a',
          'hello',
        )).reasonCode,
        'state_changed',
      );
      expect(
        (await data.finance.postDisputeMessage(
          'dispute-a',
          'hello',
        )).reasonCode,
        'refetch_required',
      );
      t.reads['dispute'] = const WorkerWireResponse(200, {
        'id': 'dispute-a',
        'scope': {'bookingId': 'b-20'},
        'status': 'open',
        'statusHistory': [],
        'messages': [],
        'canReply': true,
      });
      expect(
        await data.finance.fetchDispute('dispute-a'),
        isA<c.ReadSuccess<DisputeView>>(),
      );
      t.writes['post_dispute_message'] = const WorkerWireResponse(422, {
        'errors': {
          'message': ['secret validation content'],
          'adminSecret': ['x'],
        },
      });
      final invalid = await data.finance.postDisputeMessage(
        'dispute-a',
        'hello',
      );
      expect(invalid.status, c.CommandStatus.rejected);
      expect(invalid.fieldErrors, {
        'message': ['invalid'],
      });
    },
  );

  test(
    'profile, offer, dispute, notification and mission writes invalidate their real domains',
    () async {
      final t = _FakeTransport();
      for (final key in [
        'save_profile',
        'offer_decision',
        'post_dispute_message',
        'mark_notification_read',
        'mission_start_travel',
      ]) {
        t.writes[key] = const WorkerWireResponse(200, {});
      }
      final data = await _started(t);
      final seen = <c.DomainInvalidation>[];
      final sub = data.runtime.invalidations.listen(seen.add);
      await data.access.saveProfile(ProfileDraft({'displayName': 'Synthetic'}));
      await data.work.submitOfferDecision(
        _scope,
        OfferDecision(kind: OfferDecisionKind.acceptAll),
      );
      await data.finance.postDisputeMessage('dispute-a', 'Synthetic reply');
      await data.communications.markNotificationRead('notif-a');
      await data.mission.submit(
        SimpleMissionCommand(_scope, SimpleMissionAction.startTravel),
      );
      expect(seen.map((s) => s.topic).toList(), [
        c.InvalidationTopic.profile,
        c.InvalidationTopic.agenda,
        c.InvalidationTopic.dispute,
        c.InvalidationTopic.notifications,
        c.InvalidationTopic.booking,
      ]);
      expect(seen[1].scope?.sessionId, 'visit-1');
      expect(seen[2].entityKey, 'dispute-a');
      await sub.cancel();
    },
  );

  test(
    'single realtime stream ignores duplicates, wrong identity and unknown events',
    () async {
      final runtime = WorkerRuntimeAdapter();
      await runtime.replaceIdentity(
        _ctx,
        phase: p.RuntimePhase.signedIn,
        connection: p.ConnectionState.online,
      );
      final stream = StreamController<WorkerRealtimeNotice>.broadcast(
        sync: true,
      );
      runtime.bindEvents(stream.stream);
      expect(() => runtime.bindEvents(stream.stream), throwsStateError);
      final received = <c.DomainInvalidation>[];
      final sub = runtime.invalidations.listen(received.add);
      const wrong = WorkerRealtimeNotice(
        name: 'UnknownEvent',
        userId: 'u-test',
        workerId: 'w-test',
        generation: 'gen-one',
        eventId: '1',
      );
      stream.add(wrong);
      final good = WorkerRealtimeNotice(
        name: 'CleaningBookingTrackingUpdated',
        userId: 'u-test',
        workerId: 'w-test',
        generation: 'gen-one',
        eventId: '2',
        scope: _scope,
      );
      stream.add(good);
      stream.add(good);
      stream.add(
        WorkerRealtimeNotice(
          name: 'CleaningBookingCreated',
          userId: 'other',
          workerId: 'w-test',
          generation: 'gen-one',
          eventId: '3',
        ),
      );
      stream.add(
        const WorkerRealtimeNotice(
          name: 'CleaningBookingCreated',
          userId: 'u-test',
          workerId: 'w-test',
          generation: 'old',
          eventId: '4',
        ),
      );
      expect(received.length, 1);
      expect(received.single.generation, 'gen-one');
      expect(received.single.topic, c.InvalidationTopic.booking);
      await runtime.purgeSessionData();
      stream.add(good);
      expect(received.length, 1);
      await sub.cancel();
      await stream.close();
      await runtime.dispose();
    },
  );

  test(
    'transport only receives opaque fixture operations; never an invented URL',
    () async {
      final t = _FakeTransport()
        ..reads['profile'] = const WorkerWireResponse(200, {
          'workerId': 'w-test',
          'displayName': 'Test worker',
          'accountState': 'active',
          'editableValues': {},
          'workPreferences': {},
          'phone': null,
        });
      final data = await _started(t);
      expect(
        await data.access.fetchProfile(),
        isA<c.ReadSuccess<WorkerProfileView>>(),
      );
      expect(t.requests.single.operation, 'profile');
      expect(t.requests.single.operation, isNot(contains('/api/')));
      expect(t.requests.single.arguments, isEmpty);
      expect(jsonEncode(t.requests.single.arguments), isNot(contains('token')));
    },
  );
}
