import 'dart:async';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/ports.dart'
    as wr;
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/design_system/design_system.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/features/work/module.dart';

class WorkRuntimeFixture implements wr.WorkerRuntimePort {
  WorkRuntimeFixture({this.offline = false});
  bool offline;
  bool authenticated = true;
  final events = StreamController<DomainInvalidation>.broadcast();
  WorkerSessionContext session = WorkerSessionContext(
    userId: 'u-1',
    workerId: 'w-1',
    generation: 'g-1',
  );
  @override
  WorkerSessionContext? get context => authenticated ? session : null;
  @override
  wr.RuntimePhase get phase =>
      authenticated ? wr.RuntimePhase.signedIn : wr.RuntimePhase.signedOut;
  @override
  wr.ConnectionState get connection =>
      offline ? wr.ConnectionState.offline : wr.ConnectionState.online;
  @override
  Stream<DomainInvalidation> get invalidations => events.stream;
  @override
  void invalidate(
    InvalidationTopic topic, {
    WorkScope? scope,
    String? entityKey,
  }) {}
  @override
  Future<void> purgeSessionData() async {
    authenticated = false;
  }
}

class WorkPortFixture implements wr.WorkPort {
  OfferView? overrideOffer;
  bool expiredCache = false;
  final visitOne = AgendaItemView(
    key: 'v-1',
    scope: WorkScope(
      bookingId: 'booking-1',
      sessionId: 'session-5',
      assignmentId: 'assignment-8',
    ),
    scheduledDate: '2026-10-23',
    status: 'assigned',
    ownAssignmentStatus: 'accepted',
    work: const WorkSummary(
      label: 'Morning visit',
      type: 'cleaning',
      area: 'Aleppo',
    ),
    operational: OperationalContext(
      executionOwner: ExecutionOwner.supervisor,
      executionCapability: false,
      allowedActions: {WorkerAction.view},
      canRecordAttendance: true,
      blockedReasons: {'supervisor_managed'},
    ),
    startsAt: DateTime.utc(2026, 10, 23, 7),
  );
  late final visitLater = AgendaItemView(
    key: 'v-2',
    scope: WorkScope(
      bookingId: 'booking-1',
      sessionId: 'session-6',
      assignmentId: 'assignment-9',
    ),
    scheduledDate: '2026-10-26',
    status: 'assigned',
    ownAssignmentStatus: 'accepted',
    work: const WorkSummary(label: 'Later visit', type: 'cleaning'),
    operational: OperationalContext(
      executionOwner: ExecutionOwner.worker,
      executionCapability: true,
      allowedActions: {WorkerAction.view},
      canRecordAttendance: true,
    ),
  );
  late final unknownTime = AgendaItemView(
    key: 'v-3',
    scope: WorkScope(bookingId: 'booking-2', sessionId: 'session-7'),
    scheduledDate: '2026-10-23',
    status: 'assigned',
    ownAssignmentStatus: 'accepted',
    work: const WorkSummary(label: 'Time unknown visit', type: 'cleaning'),
    operational: OperationalContext(
      executionOwner: null,
      executionCapability: false,
      allowedActions: {WorkerAction.view},
      canRecordAttendance: false,
    ),
  );
  late final offer = OfferView(
    bookingId: 'offer-10',
    bookingType: 'group',
    discoverable: true,
    eligible: true,
    work: const WorkSummary(
      label: 'Unaccepted offer',
      type: 'cleaning',
      area: 'Aleppo',
    ),
    acceptanceModes: ['accept_selected', 'decline'],
    visitChoices: [
      WorkScope(bookingId: 'offer-10', sessionId: 'offer-session-1'),
      WorkScope(bookingId: 'offer-10', sessionId: 'offer-session-2'),
    ],
    pricingIsFinal: true,
    workerAmount: MoneyValue(decimal: '0.00', currency: 'SYP'),
  );
  int decisionCalls = 0;
  int offersCalls = 0;
  OfferDecision? lastDecision;
  WorkScope? lastScope;
  Completer<CommandResult>? delayedDecision;
  CommandResult? nextDecision;
  AgendaQuery? lastAgenda;
  int todayCalls = 0;
  ReadResult<TodayView>? nextTodayResult;
  ReadResult<AgendaView>? nextAgendaResult;
  ReadResult<Page<JobSummaryView>>? nextBookingsResult;
  Completer<ReadResult<TodayView>>? pendingToday;

  static ReadSuccess<T> ok<T>(T value) => ReadSuccess<T>(
    value: value,
    fetchedAt: DateTime.now().toUtc(),
    freshness: ReadFreshness.fresh,
  );

  ReadSuccess<T> result<T>(T value) => ReadSuccess<T>(
    value: value,
    fetchedAt: expiredCache
        ? DateTime.now().toUtc().subtract(const Duration(hours: 25))
        : DateTime.now().toUtc(),
    freshness: expiredCache ? ReadFreshness.offline : ReadFreshness.fresh,
  );

  @override
  Future<ReadResult<TodayView>> fetchToday() async {
    todayCalls++;
    if (pendingToday != null) return await pendingToday!.future;
    if (nextTodayResult != null) return nextTodayResult!;
    return result(
      TodayView(
        agenda: AgendaView(
          timezone: 'Asia/Damascus',
          activeVisits: 17,
          nextVisit: visitLater,
          // Deliberately paginated: a summary of 17 cannot be derived from 1 row.
          items: Page(items: [visitOne], page: 1, lastPage: 4, total: 17),
        ),
        readiness: ReadinessView(
          accountState: 'active',
          completenessItems: const [],
          canReceiveRequests: true,
          financialRestrictionCodes: const [],
          remedyDestinations: const {},
        ),
      ),
    );
  }

  @override
  Future<ReadResult<Page<OfferView>>> fetchOffers(OfferQuery query) async {
    offersCalls++;
    return result(
      Page(
        items: [overrideOffer ?? offer],
        page: query.page.page,
        lastPage: 1,
        total: 1,
      ),
    );
  }

  @override
  Future<ReadResult<Page<JobSummaryView>>> fetchMyBookings(
    BookingQuery query,
  ) async {
    if (nextBookingsResult != null) return nextBookingsResult!;
    return ok(
      Page(
        items: [
          JobSummaryView(
            bookingId: 'booking-1',
            reference: 'R-1',
            bookingStatus: 'accepted',
            ownAssignmentStatus: 'accepted',
            work: const WorkSummary(label: 'Multi-visit job', type: 'cleaning'),
            visitCount: 2,
          ),
        ],
        page: 1,
        lastPage: 1,
        total: 1,
      ),
    );
  }

  @override
  Future<ReadResult<OfferView>> fetchOffer(String bookingId) async {
    final selected = overrideOffer ?? offer;
    if (bookingId != selected.bookingId) {
      return ReadFailure(
        PortFailure(kind: FailureKind.notFound, reasonCode: 'not_found'),
      );
    }
    return result(selected);
  }

  @override
  Future<CommandResult> submitOfferDecision(
    WorkScope scope,
    OfferDecision decision,
  ) async {
    decisionCalls++;
    lastScope = scope;
    lastDecision = decision;
    if (delayedDecision != null) return delayedDecision!.future;
    return nextDecision ?? CommandResult(status: CommandStatus.confirmed);
  }

  @override
  Future<ReadResult<AgendaView>> fetchAgenda(AgendaQuery query) async {
    lastAgenda = query;
    if (nextAgendaResult != null) return nextAgendaResult!;
    final options = [visitOne, visitLater, unknownTime]
        .where(
          (item) =>
              query.dates != null &&
              item.scheduledDate.compareTo(query.dates!.from) >= 0 &&
              item.scheduledDate.compareTo(query.dates!.to) <= 0,
        )
        .toList();
    return ok(
      AgendaView(
        timezone: 'Asia/Damascus',
        activeVisits: 17,
        nextVisit: visitLater,
        items: Page(
          items: options,
          page: query.page.page,
          lastPage: 1,
          total: options.length,
        ),
      ),
    );
  }
}

Future<void> showWork(
  WidgetTester tester,
  WorkPortFixture port,
  WorkRuntimeFixture runtime, {
  WorkerDestination page = WorkerDestination.today,
  ValueChanged<RouteIntent>? navigate,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: WorkerV2Theme.light(),
      home: WorkDiscoveryModule(
        port: port,
        runtime: runtime,
        initialPage: page,
        businessDate: '2026-10-23',
        locale: const Locale('en'),
        onNavigate: navigate ?? (_) {},
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('Today summary is authoritative, not sum of paginated visits', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    final intents = <RouteIntent>[];
    await showWork(tester, port, runtime, navigate: intents.add);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('Morning visit'), findsOneWidget);
    expect(find.text('Unaccepted offer'), findsNothing);
    await tester.ensureVisible(find.text('View details').first);
    await tester.tap(find.text('View details').first);
    expect(intents, hasLength(1));
    expect(intents.single.destination, WorkerDestination.mission);
    expect(intents.single.origin, RouteOrigin.today);
    // Next visit has a distinct identity although the parent booking is shared.
    expect(intents.single.scope!.sessionId, 'session-6');
    expect(intents.single.scope!.assignmentId, 'assignment-9');
    expect(intents.single.entityId, 'booking-1');
  });

  testWidgets(
    'schedule uses authoritative visit dates and preserves null time',
    (tester) async {
      final runtime = WorkRuntimeFixture();
      final port = WorkPortFixture();
      await showWork(tester, port, runtime, page: WorkerDestination.schedule);
      expect(port.lastAgenda!.dates!.from, '2026-10-19');
      expect(port.lastAgenda!.dates!.to, '2026-10-25');
      expect(find.text('Time unknown visit'), findsWidgets);
      expect(find.text('Time not provided'), findsWidgets);
      expect(find.text('Later visit'), findsNothing);
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();
      expect(port.lastAgenda!.dates!.from, '2026-10-26');
      await tester.tap(find.text('Mon\n26'));
      await tester.pumpAndSettle();
      expect(find.text('Later visit'), findsOneWidget);
    },
  );

  testWidgets(
    'offers never open mission and decisions require chosen sessions',
    (tester) async {
      final runtime = WorkRuntimeFixture();
      final port = WorkPortFixture();
      final intents = <RouteIntent>[];
      await showWork(
        tester,
        port,
        runtime,
        page: WorkerDestination.jobs,
        navigate: intents.add,
      );
      await tester.tap(find.text('View details').first);
      await tester.pumpAndSettle();
      expect(find.text('0.00 SYP'), findsOneWidget);
      expect(intents, isEmpty);
      await tester.ensureVisible(find.text('Accept selected visits').first);
      await tester.tap(find.text('Accept selected visits').first);
      await tester.pumpAndSettle();
      expect(port.decisionCalls, 0);
      await tester.tap(find.text('offer-session-2').last);
      await tester.pump();
      await tester.tap(find.text('Accept selected visits').last);
      await tester.pumpAndSettle();
      expect(port.decisionCalls, 1);
      expect(port.lastScope!.bookingId, 'offer-10');
      expect(port.lastScope!.sessionId, isNull);
      expect(port.lastDecision!.kind, OfferDecisionKind.acceptSelected);
      expect(port.lastDecision!.selectedSessionIds, ['offer-session-2']);
      expect(intents, isEmpty);
    },
  );

  testWidgets('no decision may be submitted while offline', (tester) async {
    final runtime = WorkRuntimeFixture(offline: true);
    final port = WorkPortFixture();
    await showWork(tester, port, runtime, page: WorkerDestination.jobs);
    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('offline'), findsWidgets);
    expect(port.decisionCalls, 0);
    expect(find.text('Accept selected visits'), findsOneWidget);
  });

  testWidgets('expired cached data cannot render an actionable next visit', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture(offline: true);
    final port = WorkPortFixture()..expiredCache = true;
    final intents = <RouteIntent>[];
    await showWork(tester, port, runtime, navigate: intents.add);
    expect(find.text('Morning visit'), findsNothing);
    expect(find.text('Unaccepted offer'), findsNothing);
    expect(intents, isEmpty);
  });

  testWidgets('legacy and accept-all decisions have no implicit selected IDs', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    port.overrideOffer = OfferView(
      bookingId: 'legacy-1',
      bookingType: 'single',
      discoverable: true,
      eligible: true,
      work: const WorkSummary(label: 'Legacy visit', type: 'cleaning'),
      acceptanceModes: ['accept_legacy'],
      visitChoices: [],
      pricingIsFinal: true,
    );
    await showWork(tester, port, runtime, page: WorkerDestination.jobs);
    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Accept this booking').first);
    await tester.tap(find.text('Accept this booking').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept this booking').last);
    await tester.pumpAndSettle();
    expect(port.lastDecision!.kind, OfferDecisionKind.acceptLegacy);
    expect(port.lastDecision!.selectedSessionIds, isEmpty);
    expect(port.lastScope!.bookingId, 'legacy-1');
  });

  testWidgets('only verified worker session may render authorized jobs', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture()..authenticated = false;
    final port = WorkPortFixture();
    await showWork(tester, port, runtime);
    expect(port.todayCalls, 0);
    expect(find.text('Morning visit'), findsNothing);
  });

  testWidgets(
    'uncertain decision requires server refresh before another write',
    (tester) async {
      final runtime = WorkRuntimeFixture();
      final port = WorkPortFixture()
        ..nextDecision = CommandResult(status: CommandStatus.outcomeUnknown);
      await showWork(tester, port, runtime, page: WorkerDestination.jobs);
      await tester.tap(find.text('View details').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Decline').first);
      await tester.tap(find.text('Decline').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decline').last);
      await tester.pumpAndSettle();
      expect(port.decisionCalls, 1);
      // The same sheet remains blocked until a fresh authoritative read.
      expect(find.textContaining('unknown'), findsWidgets);
    },
  );

  testWidgets('pending decision cannot be submitted twice', (tester) async {
    final runtime = WorkRuntimeFixture();
    final pending = Completer<CommandResult>();
    final port = WorkPortFixture()..delayedDecision = pending;
    await showWork(tester, port, runtime, page: WorkerDestination.jobs);
    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Decline').first);
    await tester.tap(find.text('Decline').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline').last);
    await tester.pump();
    expect(port.decisionCalls, 1);
    // No second enabled button is available until the command completes.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    pending.complete(CommandResult(status: CommandStatus.confirmed));
    await tester.pumpAndSettle();
    expect(port.decisionCalls, 1);
  });

  testWidgets('Today 404 conceals old visit and denies its mission route', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    final intents = <RouteIntent>[];
    await showWork(tester, port, runtime, navigate: intents.add);
    expect(find.text('Morning visit'), findsOneWidget);

    port.nextTodayResult = ReadFailure(
      PortFailure(kind: FailureKind.notFound, reasonCode: 'not_found'),
    );
    await tester.tap(find.byIcon(Icons.refresh).first);
    await tester.pumpAndSettle();
    expect(find.text('Morning visit'), findsNothing);
    expect(find.text('Later visit'), findsNothing);
    expect(find.text('View details'), findsNothing);
    expect(intents, isEmpty);
  });

  testWidgets('Agenda 404 clears selected visit after a prior success', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    final intents = <RouteIntent>[];
    await showWork(
      tester,
      port,
      runtime,
      page: WorkerDestination.schedule,
      navigate: intents.add,
    );
    expect(find.text('Morning visit'), findsOneWidget);

    port.nextAgendaResult = ReadFailure(
      PortFailure(kind: FailureKind.notFound, reasonCode: 'not_found'),
    );
    await tester.tap(find.byIcon(Icons.refresh).first);
    await tester.pumpAndSettle();
    expect(find.text('Morning visit'), findsNothing);
    expect(find.text('View details'), findsNothing);
    expect(intents, isEmpty);
  });

  testWidgets('Jobs 404 clears prior assigned booking', (tester) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    await showWork(tester, port, runtime, page: WorkerDestination.jobs);
    await tester.tap(find.text('Assigned work').first);
    await tester.pumpAndSettle();
    expect(find.text('Multi-visit job'), findsOneWidget);

    port.nextBookingsResult = ReadFailure(
      PortFailure(kind: FailureKind.notFound, reasonCode: 'not_found'),
    );
    await tester.tap(find.byIcon(Icons.refresh).first);
    await tester.pumpAndSettle();
    expect(find.text('Multi-visit job'), findsNothing);
  });

  testWidgets('network refresh failure cannot authorize an old mission', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    final intents = <RouteIntent>[];
    await showWork(tester, port, runtime, navigate: intents.add);
    port.nextTodayResult = ReadFailure(
      PortFailure(kind: FailureKind.network, reasonCode: 'offline'),
    );
    await tester.tap(find.byIcon(Icons.refresh).first);
    await tester.pumpAndSettle();
    expect(find.text('Morning visit'), findsOneWidget);
    await tester.ensureVisible(find.text('View details').first);
    // A transient error may retain its read-only summary, but not authority.
    expect(
      tester
          .widget<WrActionButton>(
            find.widgetWithText(WrActionButton, 'View details').first,
          )
          .onPressed,
      isNull,
    );
    expect(intents, isEmpty);
  });

  testWidgets('switching worker conceals retained Today during slow fetch', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    await showWork(tester, port, runtime);
    expect(find.text('Morning visit'), findsOneWidget);
    final late = Completer<ReadResult<TodayView>>();
    port.pendingToday = late;
    runtime.session = WorkerSessionContext(
      userId: 'u-2',
      workerId: 'w-2',
      generation: 'g-2',
    );
    await showWork(tester, port, runtime, settle: false);
    expect(find.text('Morning visit'), findsNothing);
    expect(find.text('Later visit'), findsNothing);

    runtime.authenticated = false;
    await showWork(tester, port, runtime, settle: false);
    late.complete(
      ReadFailure(
        PortFailure(kind: FailureKind.notFound, reasonCode: 'not_found'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Morning visit'), findsNothing);
  });

  testWidgets('pending and unknown assignment statuses never open mission', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    final intents = <RouteIntent>[];
    AgendaItemView visit(String label, String status) => AgendaItemView(
      key: 'key-$label',
      scope: WorkScope(bookingId: 'b-$label', sessionId: 's-$label'),
      scheduledDate: '2026-10-23',
      status: 'assigned',
      ownAssignmentStatus: status,
      work: WorkSummary(label: label, type: 'cleaning'),
      operational: OperationalContext(
        executionOwner: ExecutionOwner.worker,
        executionCapability: true,
        allowedActions: {WorkerAction.view},
        canRecordAttendance: true,
      ),
    );
    final pending = visit('Pending visit', 'pending');
    final unknown = visit('Unknown visit', 'future_unreviewed');
    final accepted = visit(
      'Accepted visit',
      'accepted_waiting_for_order_start',
    );
    port.nextTodayResult = WorkPortFixture.ok(
      TodayView(
        agenda: AgendaView(
          timezone: 'Asia/Damascus',
          activeVisits: 3,
          nextVisit: pending,
          items: Page(
            items: [pending, unknown, accepted],
            page: 1,
            lastPage: 1,
            total: 3,
          ),
        ),
        readiness: ReadinessView(
          accountState: 'active',
          completenessItems: const [],
          canReceiveRequests: true,
          financialRestrictionCodes: const [],
          remedyDestinations: const {},
        ),
      ),
    );
    await showWork(tester, port, runtime, navigate: intents.add);
    expect(find.text('Pending visit'), findsNothing);
    expect(find.text('Unknown visit'), findsNothing);
    expect(find.text('Accepted visit'), findsOneWidget);
    await tester.ensureVisible(find.text('View details').first);
    await tester.tap(find.text('View details').first);
    expect(intents, hasLength(1));
    expect(intents.single.scope!.bookingId, 'b-Accepted visit');
  });

  testWidgets('A open decision sheet cannot submit after runtime switches B', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final port = WorkPortFixture();
    await showWork(tester, port, runtime, page: WorkerDestination.jobs);
    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline').first);
    await tester.pumpAndSettle();
    expect(find.text('Unaccepted offer'), findsWidgets);

    runtime.session = WorkerSessionContext(
      userId: 'user-B',
      workerId: 'worker-B',
      generation: 'generation-B',
    );
    // No parent rebuild yet: the old sheet's mounted callback is still live.
    await tester.tap(find.text('Decline').last);
    await tester.pumpAndSettle();
    expect(port.decisionCalls, 0);
    expect(port.lastScope, isNull);
  });

  testWidgets('A delayed decision result never clears B offer or locks B', (
    tester,
  ) async {
    final runtime = WorkRuntimeFixture();
    final pending = Completer<CommandResult>();
    final port = WorkPortFixture()..delayedDecision = pending;
    await showWork(tester, port, runtime, page: WorkerDestination.jobs);
    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline').last);
    await tester.pump();
    expect(port.decisionCalls, 1);
    final offersBeforeB = port.offersCalls;

    runtime.session = WorkerSessionContext(
      userId: 'user-B',
      workerId: 'worker-B',
      generation: 'generation-B',
    );
    port.overrideOffer = OfferView(
      bookingId: 'offer-B',
      bookingType: 'single',
      discoverable: true,
      eligible: true,
      work: const WorkSummary(label: 'Only B offer', type: 'cleaning'),
      acceptanceModes: ['decline'],
      visitChoices: [],
      pricingIsFinal: true,
    );
    await showWork(tester, port, runtime, page: WorkerDestination.jobs);
    expect(find.text('Unaccepted offer'), findsNothing);
    expect(find.text('Only B offer'), findsOneWidget);
    expect(port.offersCalls, greaterThan(offersBeforeB));
    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();
    expect(find.text('Only B offer'), findsOneWidget);

    final offersBeforeLateA = port.offersCalls;
    pending.complete(CommandResult(status: CommandStatus.confirmed));
    await tester.pumpAndSettle();
    expect(find.text('Only B offer'), findsOneWidget);
    expect(port.offersCalls, offersBeforeLateA);
    expect(port.decisionCalls, 1);
    await tester.tap(find.text('Decline').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline').last);
    await tester.pumpAndSettle();
    expect(port.decisionCalls, 2);
    expect(port.lastScope!.bookingId, 'offer-B');
  });
}
