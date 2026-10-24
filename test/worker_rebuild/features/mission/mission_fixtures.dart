import 'dart:async';

import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/ports.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';

/// Entirely synthetic fixture identities. This file makes no live API claims.
final fixtureSession = WorkerSessionContext(
  userId: 'fixture-user',
  workerId: 'fixture-worker',
  generation: 'fixture-generation',
);
final bookingScope = WorkScope(bookingId: 'booking-fixture');
final firstVisit = WorkScope(
  bookingId: 'booking-fixture',
  sessionId: 'visit-one',
  assignmentId: 'own-assignment',
);
final secondVisit = WorkScope(
  bookingId: 'booking-fixture',
  sessionId: 'visit-two',
  assignmentId: 'second-assignment',
);

MissionView fixtureMission(
  WorkScope scope, {
  bool execution = true,
  bool attendance = true,
  ExecutionOwner? owner = ExecutionOwner.worker,
  Set<WorkerAction> actions = const {WorkerAction.view},
  List<MissionServiceLineView> serviceLines = const [],
  List<String> waitingReasons = const [],
  String? customerLocation,
  String? customerPhone,
}) => MissionView(
  scope: scope,
  status: 'assigned',
  stage: 'ready',
  ownAssignmentStatus: 'accepted',
  operational: OperationalContext(
    executionOwner: owner,
    executionCapability: execution,
    canRecordAttendance: attendance,
    allowedActions: actions,
  ),
  ownServices: const ['Kitchen', 'Kitchen'],
  ownRooms: const ['Living room'],
  serviceLines: serviceLines,
  waitingReasons: waitingReasons,
  customerLocation: customerLocation,
  customerPhone: customerPhone,
);

ReadSuccess<T> fresh<T>(T value) => ReadSuccess<T>(
  value: value,
  fetchedAt: DateTime.utc(2026, 10, 22, 10),
  freshness: ReadFreshness.fresh,
);

class FakeRuntime implements WorkerRuntimePort {
  FakeRuntime({WorkerSessionContext? context})
      : contextValue = context ?? fixtureSession;

  WorkerSessionContext? contextValue;
  RuntimePhase phaseValue = RuntimePhase.signedIn;
  ConnectionState connectionValue = ConnectionState.online;

  @override
  WorkerSessionContext? get context => contextValue;
  @override
  RuntimePhase get phase => phaseValue;
  @override
  ConnectionState get connection => connectionValue;
  @override
  Stream<DomainInvalidation> get invalidations => const Stream.empty();
  @override
  void invalidate(InvalidationTopic topic, {WorkScope? scope, String? entityKey}) {}
  @override
  Future<void> purgeSessionData() async {}
}

class FakeMissionPort implements MissionPort {
  FakeMissionPort(this.views);
  final Map<String, MissionView> views;
  final List<WorkScope> requested = [];
  final List<MissionCommand> submitted = [];
  final Map<String, Completer<ReadResult<MissionView>>> delayed = {};
  final Map<String, InventoryView> inventories = {};
  final Map<String, List<DecisionView>> decisions = {};
  ReadFreshness freshness = ReadFreshness.fresh;
  CommandStatus commandStatus = CommandStatus.confirmed;
  Completer<CommandResult>? delayedCommand;
  PortFailure? readFailure;
  PortFailure? inventoryFailure;
  int verificationReads = 0;
  int fetchCount = 0;

  @override
  Future<ReadResult<MissionView>> fetchMission(WorkScope scope) => _read(scope);
  @override
  Future<ReadResult<MissionView>> fetchVisitScope(WorkScope scope) => _read(scope);

  Future<ReadResult<MissionView>> _read(WorkScope scope) async {
    requested.add(scope);
    fetchCount++;
    final wait = delayed[scope.cacheKey];
    if (wait != null) return wait.future;
    if (readFailure != null) return ReadFailure<MissionView>(readFailure!);
    final view = views[scope.cacheKey];
    if (view == null) {
      return ReadFailure<MissionView>(
        PortFailure(kind: FailureKind.notFound, reasonCode: 'not_found'),
      );
    }
    return ReadSuccess<MissionView>(
      value: view,
      fetchedAt: DateTime.utc(2026, 10, 22, 10),
      freshness: freshness,
    );
  }

  @override
  Future<ReadResult<InventoryView>> fetchInventory(WorkScope scope) async =>
      inventoryFailure == null
          ? fresh(inventories[scope.cacheKey] ?? InventoryView(scope: scope, items: []))
          : ReadFailure<InventoryView>(inventoryFailure!);

  @override
  Future<ReadResult<List<DecisionView>>> fetchDecisions(WorkScope scope) async =>
      fresh(decisions[scope.cacheKey] ?? <DecisionView>[]);

  @override
  Future<ReadResult<String?>> fetchVerificationCode(WorkScope scope) async {
    verificationReads++;
    return fresh<String?>('DEMO-CODE');
  }

  @override
  Future<CommandResult> submit(MissionCommand command) async {
    submitted.add(command);
    if (delayedCommand != null) return delayedCommand!.future;
    return CommandResult(status: commandStatus, scope: command.scope);
  }
}
