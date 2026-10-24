import '../common.dart';
import '../models.dart';
import '../navigation.dart';

/// Contract-test and prototype data. No identity/price/action here is evidence
/// of a live server or a permission grant. Scenarios are intentionally explicit.
class BaseFixture {
  const BaseFixture({
    required this.code,
    required this.scope,
    required this.operational,
    this.money,
    this.earning,
    this.destination,
    this.expectedReason,
    this.bookingKind,
    this.intervals = const [],
    this.boundsAmbiguous = false,
    this.discoverable,
    this.assigned,
    this.totalsByCurrency = const {},
    this.depositEligible,
    this.notificationId,
    this.cacheAgeSeconds,
    this.denied,
    this.commandOutcome,
  });
  final String code;
  final WorkScope scope;
  final OperationalContext operational;
  final MoneyValue? money;
  final EarningEntryView? earning;
  final RouteIntent? destination;
  final String? expectedReason;
  final String? bookingKind;
  final List<FixtureInterval> intervals;
  final bool boundsAmbiguous;
  final bool? discoverable;
  final bool? assigned;
  final Map<String, String> totalsByCurrency;
  final bool? depositEligible;
  final String? notificationId;
  final int? cacheAgeSeconds;
  final bool? denied;
  final CommandStatus? commandOutcome;
}

class FixtureInterval {
  const FixtureInterval(this.start, this.end);
  final String start;
  final String end;
}

class BaseFixtures {
  const BaseFixtures._();

  static final legacyScope = WorkScope(bookingId: '101');
  static final supervisedVisit = WorkScope(
    bookingId: '202',
    sessionId: '301',
    assignmentId: '401',
  );
  static final laterVisit = WorkScope(
    bookingId: '202',
    sessionId: '302',
    assignmentId: '402',
  );

  static OperationalContext operational({
    ExecutionOwner? owner = ExecutionOwner.worker,
    bool execution = true,
    bool attendance = true,
    Set<WorkerAction> actions = const {WorkerAction.view},
    Set<String> reasons = const {},
  }) => OperationalContext(
    executionOwner: owner,
    executionCapability: execution,
    allowedActions: actions,
    blockedReasons: reasons,
    canRecordAttendance: attendance,
  );

  static final List<BaseFixture> scenarios = List.unmodifiable([
    BaseFixture(
      code: 'legacy_single_worker',
      scope: legacyScope,
      operational: operational(
        actions: {
          WorkerAction.view,
          WorkerAction.startTravel,
          WorkerAction.arrive,
        },
      ),
    ),
    BaseFixture(
      code: 'standard_kind_supervisor_v2',
      scope: supervisedVisit,
      operational: operational(
        owner: ExecutionOwner.supervisor,
        execution: false,
        attendance: true,
        reasons: {'supervisor_managed'},
      ),
      expectedReason: 'supervisor_managed',
      bookingKind: 'standard',
    ),
    BaseFixture(
      code: 'independent_later_visit',
      scope: laterVisit,
      operational: operational(
        owner: ExecutionOwner.supervisor,
        execution: false,
        reasons: {'not_yet_available'},
      ),
      expectedReason: 'not_yet_available',
    ),
    BaseFixture(
      code: 'room_interval_overlap_gap',
      scope: supervisedVisit,
      operational: operational(
        owner: ExecutionOwner.supervisor,
        execution: false,
        reasons: {'execution_unavailable'},
      ),
      expectedReason: 'execution_unavailable',
      intervals: const [
        FixtureInterval('2026-10-22T06:00:00Z', '2026-10-22T07:00:00Z'),
        FixtureInterval('2026-10-22T06:30:00Z', '2026-10-22T08:00:00Z'),
        FixtureInterval('2026-10-22T09:00:00Z', '2026-10-22T10:00:00Z'),
      ],
    ),
    BaseFixture(
      code: 'ambiguous_bounds',
      scope: supervisedVisit,
      operational: operational(
        owner: ExecutionOwner.supervisor,
        execution: false,
        reasons: {'unavailable'},
      ),
      expectedReason: 'unavailable',
      boundsAmbiguous: true,
    ),
    BaseFixture(
      code: 'unaccepted_discoverable_offer',
      scope: WorkScope(bookingId: '203'),
      operational: operational(
        owner: null,
        execution: false,
        attendance: false,
        reasons: {'not_assigned'},
      ),
      expectedReason: 'not_assigned',
      discoverable: true,
      assigned: false,
    ),
    BaseFixture(
      code: 'customer_wait_rework',
      scope: supervisedVisit,
      operational: operational(
        owner: ExecutionOwner.supervisor,
        execution: false,
        reasons: {'waiting_customer'},
      ),
      expectedReason: 'waiting_customer',
    ),
    BaseFixture(
      code: 'valid_zero_money',
      scope: legacyScope,
      operational: operational(),
      money: MoneyValue(decimal: '0.00', currency: 'SYP'),
    ),
    BaseFixture(
      code: 'missing_allocation',
      scope: laterVisit,
      operational: operational(),
      earning: EarningEntryView(
        key: 'session_assignment:402',
        scope: laterVisit,
        completedDate: '2026-10-22',
        currency: 'SYP',
        authoritativeAmount: null,
        reconciliationState: 'incomplete',
      ),
    ),
    BaseFixture(
      code: 'mixed_currencies',
      scope: legacyScope,
      operational: operational(),
      money: MoneyValue(decimal: '13.25', currency: 'USD'),
      totalsByCurrency: const {'USD': '13.25', 'SYP': '100.00'},
    ),
    BaseFixture(
      code: 'deposit_restriction',
      scope: legacyScope,
      operational: operational(
        execution: false,
        reasons: {'financial_restriction'},
      ),
      expectedReason: 'financial_restriction',
      depositEligible: false,
    ),
    BaseFixture(
      code: 'exact_session_dispute',
      scope: supervisedVisit,
      operational: operational(),
      destination: RouteIntent(
        destination: WorkerDestination.disputeThread,
        origin: RouteOrigin.finance,
        entityId: '500',
        scope: supervisedVisit,
      ),
    ),
    BaseFixture(
      code: 'notification_selected_session',
      scope: laterVisit,
      operational: operational(),
      destination: RouteIntent(
        destination: WorkerDestination.mission,
        origin: RouteOrigin.notification,
        scope: laterVisit,
      ),
      notificationId: '900',
    ),
    BaseFixture(
      code: 'offline_24h_expiry',
      scope: supervisedVisit,
      operational: operational(execution: false, reasons: {'unavailable'}),
      expectedReason: 'unavailable',
      cacheAgeSeconds: 86401,
    ),
    BaseFixture(
      code: 'assignment_removed',
      scope: supervisedVisit,
      operational: operational(
        execution: false,
        attendance: false,
        reasons: {'not_assigned'},
      ),
      expectedReason: 'not_assigned',
      denied: true,
    ),
    BaseFixture(
      code: 'stale_409',
      scope: supervisedVisit,
      operational: operational(execution: false, reasons: {'state_changed'}),
      expectedReason: 'state_changed',
      commandOutcome: CommandStatus.rejected,
    ),
    BaseFixture(
      code: 'uncertain_timeout',
      scope: supervisedVisit,
      operational: operational(),
      expectedReason: 'outcome_unknown',
      commandOutcome: CommandStatus.outcomeUnknown,
    ),
  ]);
}

/// Typed read records used to prove consumers can issue identity-safe commands.
class ContractIdentityFixtures {
  const ContractIdentityFixtures._();

  static final scope = WorkScope(bookingId: '707', sessionId: '808');

  static final mission = MissionView(
    scope: scope,
    status: 'in_progress',
    stage: 'work',
    ownAssignmentStatus: 'assigned',
    operational: BaseFixtures.operational(
      actions: {
        WorkerAction.startSpecialService,
        WorkerAction.finishSpecialService,
        WorkerAction.acknowledgeEquipment,
        WorkerAction.returnEquipment,
      },
    ),
    ownServices: const ['Window cleaning', 'Window cleaning'],
    serviceLines: [
      MissionServiceLineView(
        scope: scope,
        lineId: 'line-a',
        label: 'Window cleaning',
        status: 'pending',
        allowedActions: {WorkerAction.startSpecialService},
      ),
      MissionServiceLineView(
        scope: scope,
        lineId: 'line-b',
        label: 'Window cleaning',
        status: 'pending',
        allowedActions: {WorkerAction.startSpecialService},
      ),
    ],
    ownRooms: const [],
    waitingReasons: const [],
  );

  static final reservations = List<InventoryItemView>.unmodifiable([
    InventoryItemView(
      itemId: 'equipment-5',
      reservationId: 'reservation-9',
      name: 'Vacuum',
      quantity: '1',
      custodyState: 'issued',
      allowedActions: {
        WorkerAction.acknowledgeEquipment,
        WorkerAction.returnEquipment,
      },
    ),
    InventoryItemView(
      itemId: 'equipment-6',
      reservationId: 'reservation-10',
      name: 'Mop',
      quantity: '1',
      custodyState: 'issued',
      allowedActions: {
        WorkerAction.acknowledgeEquipment,
        WorkerAction.returnEquipment,
      },
    ),
  ]);
}
