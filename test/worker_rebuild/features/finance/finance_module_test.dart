import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState, Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/ports.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/features/finance/module.dart';

final _session = WorkerSessionContext(
  userId: 'u1',
  workerId: 'w1',
  generation: 'g1',
);
final _scope = WorkScope(bookingId: 'b1', sessionId: 's1', assignmentId: 'a1');

class _Runtime implements WorkerRuntimePort {
  @override
  WorkerSessionContext? context = _session;
  @override
  RuntimePhase phase = RuntimePhase.signedIn;
  @override
  ConnectionState connection = ConnectionState.online;
  @override
  Stream<DomainInvalidation> get invalidations =>
      const Stream<DomainInvalidation>.empty();
  @override
  void invalidate(
    InvalidationTopic topic, {
    WorkScope? scope,
    String? entityKey,
  }) {}
  @override
  Future<void> purgeSessionData() async {}
}

class _Finance implements FinancePort {
  int sendCount = 0;
  CommandStatus sendStatus = CommandStatus.confirmed;
  String? rejectReasonCode;
  Completer<CommandResult>? delayedReply;
  String? returnedDisputeId;
  bool failThreadRead = false;
  int disputeReads = 0;
  String? returnedEarningKey;
  WorkScope? returnedEarningScope;
  EarningsQuery? lastEarningsQuery;
  MoneyValue? debtBalance;
  Map<String, MoneyValue?> breakdown = {};
  List<DepositLedgerEntryView> ledgerEntries = [];
  List<DisputeMessageView> disputeMessages = [];
  List<String> disputeStatusHistory = [];
  bool canReply = true;
  bool paginatedDisputes = false;
  final disputePagesRequested = <int>[];
  final sentBodies = <String>[];
  ReadSuccess<T> ok<T>(T value) => ReadSuccess(
    value: value,
    fetchedAt: DateTime.utc(2026, 10, 23),
    freshness: ReadFreshness.fresh,
  );
  @override
  Future<ReadResult<EarningsView>> fetchEarnings(EarningsQuery query) async {
    lastEarningsQuery = query;
    return ok(
      EarningsView(
        entries: Page(
          items: [
            EarningEntryView(
              key: 'session_assignment:a1',
              scope: _scope,
              completedDate: '2026-10-22',
              currency: 'SYP',
              authoritativeAmount: null,
              reconciliationState: 'unavailable',
            ),
            EarningEntryView(
              key: 'session_assignment:a2',
              scope: _scope,
              completedDate: '2026-10-22',
              currency: 'SYP',
              authoritativeAmount: MoneyValue(decimal: '0', currency: 'SYP'),
              reconciliationState: 'complete',
            ),
          ],
          page: 1,
          lastPage: 1,
          total: 2,
        ),
        completedTotals: {'SYP': MoneyValue(decimal: '0', currency: 'SYP')},
        incompleteEntries: 1,
        periodLabel: 'all time',
      ),
    );
  }

  @override
  Future<ReadResult<EarningEntryView>> fetchEarning(String key) async => ok(
    EarningEntryView(
      key: returnedEarningKey ?? key,
      scope: returnedEarningScope ?? _scope,
      completedDate: '2026-10-22',
      currency: 'SYP',
      authoritativeAmount: MoneyValue(decimal: '0', currency: 'SYP'),
      reconciliationState: 'complete',
      frozenBreakdown: breakdown,
    ),
  );
  @override
  Future<ReadResult<DepositView>> fetchDeposit() async => ok(
    DepositView(
      accountStatus: 'active',
      financiallyEligible: true,
      restrictionCodes: [],
      remedyDestinations: {},
      currentBalance: MoneyValue(decimal: '300', currency: 'SYP'),
      debtBalance: debtBalance,
    ),
  );
  @override
  Future<ReadResult<Page<DepositLedgerEntryView>>> fetchDepositLedger(
    LedgerQuery query,
  ) async => ok(
    Page<DepositLedgerEntryView>(
      items: ledgerEntries,
      page: 1,
      lastPage: 1,
      total: ledgerEntries.length,
    ),
  );
  @override
  Future<ReadResult<Page<DisputeView>>> fetchDisputes(
    DisputeQuery query,
  ) async {
    final page = query.page.page;
    disputePagesRequested.add(page);
    if (!paginatedDisputes) {
      return ok(Page<DisputeView>(items: [], page: 1, lastPage: 1, total: 0));
    }
    return ok(
      Page<DisputeView>(
        items: [
          DisputeView(
            id: 'ticket$page',
            scope: _scope,
            status: 'open',
            statusHistory: [],
            messages: [],
            canReply: false,
          ),
        ],
        page: page,
        lastPage: 2,
        total: 25,
      ),
    );
  }

  @override
  Future<ReadResult<DisputeView>> fetchDispute(String disputeId) async {
    disputeReads++;
    if (failThreadRead) {
      return ReadFailure<DisputeView>(
        PortFailure(kind: FailureKind.server, reasonCode: 'read_unavailable'),
      );
    }
    return ok(
      DisputeView(
        id: returnedDisputeId ?? disputeId,
        scope: _scope,
        status: canReply ? 'open' : 'resolved',
        statusHistory: disputeStatusHistory,
        messages: disputeMessages,
        canReply: canReply,
      ),
    );
  }

  @override
  Future<CommandResult> postDisputeMessage(
    String disputeId,
    String message,
  ) async {
    sendCount++;
    sentBodies.add(message);
    if (delayedReply != null) return delayedReply!.future;
    return CommandResult(
      status: sendStatus,
      reasonCode: sendStatus == CommandStatus.rejected
          ? rejectReasonCode
          : null,
    );
  }
}

void main() {
  testWidgets(
    'missing allocation is distinct from legitimate zero and totals are server owned',
    (tester) async {
      final finance = _Finance();
      final routes = <RouteIntent>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            onNavigate: routes.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Allocations unavailable: 1'), findsOneWidget);
      expect(find.text('Amount unavailable'), findsOneWidget);
      expect(find.text('0 SYP'), findsWidgets);
      await tester.ensureVisible(find.text('View separate deposit account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View separate deposit account'));
      await tester.pump();
      expect(routes.single.destination, WorkerDestination.depositAccount);
    },
  );

  testWidgets(
    'dispute reply sends only text and unknown outcome blocks a duplicate',
    (tester) async {
      final finance = _Finance()..sendStatus = CommandStatus.outcomeUnknown;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.disputeThread,
            entityId: 'd1',
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Please inspect this order',
      );
      await tester.pump(); // Rebuild the submit action after the draft changes.
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      expect(finance.sentBodies, ['Please inspect this order']);
      expect(finance.sendCount, 1);
      expect(find.textContaining('Delivery is unconfirmed'), findsOneWidget);
      await tester.tap(find.text('Send message'), warnIfMissed: false);
      await tester.pump();
      expect(finance.sendCount, 1);
    },
  );

  testWidgets('offline dispute composer cannot dispatch writes', (
    tester,
  ) async {
    final finance = _Finance();
    final runtime = _Runtime()..connection = ConnectionState.offline;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerFinanceModule(
          finance: finance,
          runtime: runtime,
          session: _session,
          destination: WorkerDestination.disputeThread,
          entityId: 'd1',
          onNavigate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connect to view this information'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(finance.sendCount, 0);
  });

  testWidgets(
    'unknown reply requires a fresh thread and explicit review, never resends draft',
    (tester) async {
      final finance = _Finance()..sendStatus = CommandStatus.outcomeUnknown;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.disputeThread,
            entityId: 'd1',
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Uncertain message');
      await tester.pump();
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      expect(finance.sendCount, 1);
      expect(
        find.text('I reviewed the thread; compose a new message'),
        findsNothing,
      );
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(finance.disputeReads, 2);
      final review = find.text('I reviewed the thread; compose a new message');
      expect(review, findsOneWidget);
      await tester.ensureVisible(review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(finance.sendCount, 1);
      expect(find.text('Send message'), findsOneWidget);
    },
  );

  testWidgets('failed recovery read never unlocks an uncertain dispute send', (
    tester,
  ) async {
    final finance = _Finance()..sendStatus = CommandStatus.outcomeUnknown;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerFinanceModule(
          finance: finance,
          runtime: _Runtime(),
          session: _session,
          destination: WorkerDestination.disputeThread,
          entityId: 'd1',
          onNavigate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Please inspect');
    await tester.pump();
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();
    finance.failThreadRead = true;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('Data unavailable'), findsOneWidget);
    expect(
      find.text('I reviewed the thread; compose a new message'),
      findsNothing,
    );
    expect(finance.sendCount, 1);
  });

  testWidgets(
    'write authorization revocation immediately conceals dispute and draft',
    (tester) async {
      final finance = _Finance()
        ..sendStatus = CommandStatus.rejected
        ..rejectReasonCode =
            'unavailable'; // S03 maps HTTP 403 to this safe code.
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.disputeThread,
            entityId: 'd1',
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Private draft that must vanish',
      );
      await tester.pump();
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      expect(finance.sendCount, 1);
      expect(find.text('Data unavailable'), findsOneWidget);
      expect(find.text('Private draft that must vanish'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Send message'), findsNothing);
    },
  );

  testWidgets(
    '403 reply after reading private messages clears entire thread and composer',
    (tester) async {
      final finance = _Finance()
        ..sendStatus = CommandStatus.rejected
        ..rejectReasonCode = 'unavailable'
        ..disputeMessages = [
          DisputeMessageView(
            id: 'm1',
            sentAt: DateTime.utc(2026, 10, 23, 12, 5),
            body: 'Previously visible private message',
            senderLabel: 'support',
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.disputeThread,
            entityId: 'd1',
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Previously visible private message'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Private unsent reply');
      await tester.pump();
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      expect(finance.sendCount, 1);
      expect(find.text('Data unavailable'), findsOneWidget);
      expect(find.text('Previously visible private message'), findsNothing);
      expect(find.text('Private unsent reply'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('wrong dispute identity never displays or receives a reply', (
    tester,
  ) async {
    final finance = _Finance()..returnedDisputeId = 'wrong-ticket';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerFinanceModule(
          finance: finance,
          runtime: _Runtime(),
          session: _session,
          destination: WorkerDestination.disputeThread,
          entityId: 'requested',
          onNavigate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Data unavailable'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(finance.sendCount, 0);
  });

  testWidgets('stale earning key is not shown as requested entry', (
    tester,
  ) async {
    final finance = _Finance()..returnedEarningKey = 'session_assignment:other';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerFinanceModule(
          finance: finance,
          runtime: _Runtime(),
          session: _session,
          destination: WorkerDestination.earningDetail,
          entityId: 'session_assignment:a1',
          onNavigate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Data unavailable'), findsOneWidget);
  });

  testWidgets('offline transition conceals fresh deposit details', (
    tester,
  ) async {
    final runtime = _Runtime();
    final finance = _Finance();
    Widget screen() => MaterialApp(
      locale: const Locale('en'),
      home: WorkerFinanceModule(
        finance: finance,
        runtime: runtime,
        session: _session,
        destination: WorkerDestination.depositAccount,
        onNavigate: (_) {},
      ),
    );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('300 SYP'), findsOneWidget);
    runtime.connection = ConnectionState.offline;
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('Connect to view this information'), findsOneWidget);
    expect(find.text('300 SYP'), findsNothing);
  });

  testWidgets('partial session allocation cannot navigate to another visit', (
    tester,
  ) async {
    final finance = _Finance()
      ..returnedEarningScope = WorkScope(bookingId: 'b1');
    final routes = <RouteIntent>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: WorkerFinanceModule(
          finance: finance,
          runtime: _Runtime(),
          session: _session,
          destination: WorkerDestination.earningDetail,
          entityId: 'session_assignment:a1',
          onNavigate: routes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View mission'), warnIfMissed: false);
    expect(routes, isEmpty);
  });

  testWidgets('new identity/route clears orphaned pending dispute submission', (
    tester,
  ) async {
    final finance = _Finance()..delayedReply = Completer<CommandResult>();
    final runtime = _Runtime();
    Widget screen(String id) => MaterialApp(
      locale: const Locale('en'),
      home: WorkerFinanceModule(
        key: const ValueKey('finance'),
        finance: finance,
        runtime: runtime,
        session: _session,
        destination: WorkerDestination.disputeThread,
        entityId: id,
        onNavigate: (_) {},
      ),
    );
    await tester.pumpWidget(screen('d1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hello worker support');
    await tester.pump();
    await tester.tap(find.text('Send message'));
    await tester.pump();
    expect(finance.sendCount, 1);
    // Route transition must not leak the old draft or permanently lock the new composer.
    await tester.pumpWidget(screen('d2'));
    await tester.pumpAndSettle();
    expect(find.text('Hello worker support'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, true);
    finance.delayedReply!.complete(
      CommandResult(status: CommandStatus.confirmed),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Dispute d2'), findsOneWidget);
  });

  testWidgets(
    'inclusive earnings date range is sent to port without client totals',
    (tester) async {
      final finance = _Finance();
      final range = DateRange(from: '2026-10-01', to: '2026-10-07');
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            initialEarningsRange: range,
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(finance.lastEarningsQuery!.dates!.from, '2026-10-01');
      expect(finance.lastEarningsQuery!.dates!.to, '2026-10-07');
      expect(find.text('2026-10-01 — 2026-10-07'), findsOneWidget);
      expect(find.text('0 SYP'), findsWidgets);
    },
  );

  testWidgets(
    'debt balance is independent of deposit and null stays unavailable',
    (tester) async {
      final finance = _Finance()
        ..debtBalance = MoneyValue(decimal: '0', currency: 'SYP');
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.depositAccount,
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deposit balance'), findsOneWidget);
      expect(find.text('Debt balance'), findsOneWidget);
      expect(find.text('300 SYP'), findsOneWidget);
      expect(find.text('0 SYP'), findsOneWidget);
      finance.debtBalance = null;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(find.text('Debt balance'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('0 SYP'), findsNothing);
      expect(find.text('300 SYP'), findsOneWidget);
    },
  );

  testWidgets(
    'earning heading localizes source family and never shows raw key or breakdown codes',
    (tester) async {
      final finance = _Finance()
        ..breakdown = {
          'travel_fee': MoneyValue(decimal: '10', currency: 'SYP'),
          'hidden_custom_admin_field': null,
        };
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.earningDetail,
            entityId: 'session_assignment:a1',
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Completed work visit'), findsOneWidget);
      expect(find.text('Support reference'), findsOneWidget);
      expect(find.text('a1'), findsOneWidget);
      expect(find.text('Travel fee'), findsOneWidget);
      expect(find.text('Other allocation component'), findsOneWidget);
      expect(find.textContaining('session_assignment:'), findsNothing);
      expect(find.textContaining('hidden_custom_admin_field'), findsNothing);
    },
  );

  testWidgets(
    'ledger displays approved type, explicit UTC and only sanitized support references',
    (tester) async {
      final finance = _Finance()
        ..ledgerEntries = [
          DepositLedgerEntryView(
            id: 'tx1',
            occurredAt: DateTime.utc(2026, 10, 22, 7, 3),
            status: 'refund',
            amount: MoneyValue(decimal: '123.50', currency: 'SYP'),
            reference: 'person@example.com',
          ),
          DepositLedgerEntryView(
            id: 'tx2',
            occurredAt: DateTime.utc(2026, 10, 23, 2, 9),
            status: 'deposit',
            amount: MoneyValue(decimal: '0', currency: 'SYP'),
            reference: 'tx-public-2',
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.depositLedger,
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('2026-10-22 07:03 UTC'), findsOneWidget);
      expect(find.text('123.50 SYP'), findsOneWidget);
      expect(find.text('0 SYP'), findsOneWidget);
      expect(find.text('tx-public-2'), findsOneWidget);
      expect(find.textContaining('person@example.com'), findsNothing);
      expect(find.text('Page 1 of 1 · Total 2'), findsOneWidget);
    },
  );

  testWidgets(
    'dispute thread shows safe sender, UTC time and server reply restriction',
    (tester) async {
      final finance = _Finance()
        ..canReply = false
        ..disputeStatusHistory = ['open', 'resolved']
        ..disputeMessages = [
          DisputeMessageView(
            id: 'm1',
            sentAt: DateTime.utc(2026, 10, 23, 12, 5),
            body: 'The issue is being reviewed',
            senderLabel: 'support',
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.disputeThread,
            entityId: 'd1',
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current status: Resolved'), findsOneWidget);
      expect(find.text('Status history'), findsOneWidget);
      expect(find.text('Support · 2026-10-23 12:05 UTC'), findsOneWidget);
      expect(find.text('The issue is being reviewed'), findsOneWidget);
      expect(
        find.text('Replies are unavailable for this dispute'),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      expect(finance.sendCount, 0);
    },
  );

  testWidgets(
    'dispute pagination follows server page metadata and supports previous page',
    (tester) async {
      final finance = _Finance()..paginatedDisputes = true;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: WorkerFinanceModule(
            finance: finance,
            runtime: _Runtime(),
            session: _session,
            destination: WorkerDestination.disputes,
            onNavigate: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dispute ticket1'), findsOneWidget);
      expect(find.text('Page 1 of 2 · Total 25'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Dispute ticket2'), findsOneWidget);
      expect(find.text('Dispute ticket1'), findsNothing);
      expect(find.text('Page 2 of 2 · Total 25'), findsOneWidget);
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(finance.disputePagesRequested, [1, 2, 1]);
      expect(find.text('Dispute ticket1'), findsOneWidget);
    },
  );

  testWidgets(
    'Arabic finance overview localizes work label with isolated ASCII date',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: const Locale('ar'),
              child: WorkerFinanceModule(
                finance: _Finance(),
                runtime: _Runtime(),
                session: _session,
                onNavigate: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('زيارة عمل مكتملة'), findsNWidgets(2));
      expect(find.textContaining('\u20662026-10-22\u2069'), findsWidgets);
      expect(find.textContaining('session_assignment:'), findsNothing);
    },
  );

  testWidgets(
    'Arabic earning detail and ledger isolate safe references and UTC digits',
    (tester) async {
      final finance = _Finance()
        ..breakdown = {
          'travel_fee': MoneyValue(decimal: '12', currency: 'SYP'),
          'private_internal_key': null,
        };
      Future<void> render(WorkerDestination destination) async {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(destination),
            home: Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: const Locale('ar'),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: WorkerFinanceModule(
                    finance: finance,
                    runtime: _Runtime(),
                    session: _session,
                    destination: destination,
                    entityId: destination == WorkerDestination.earningDetail
                        ? 'session_assignment:a1'
                        : null,
                    onNavigate: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render(WorkerDestination.earningDetail);
      expect(find.text('زيارة عمل مكتملة'), findsOneWidget);
      expect(find.text('مرجع للدعم'), findsOneWidget);
      expect(find.text('\u2066a1\u2069'), findsOneWidget);
      expect(find.text('بدل التنقل'), findsOneWidget);
      expect(find.text('بند مخصصات آخر'), findsOneWidget);
      expect(find.textContaining('private_internal_key'), findsNothing);
      expect(find.textContaining('session_assignment:'), findsNothing);

      finance.ledgerEntries = [
        DepositLedgerEntryView(
          id: 'tx1',
          occurredAt: DateTime.utc(2026, 10, 22, 7, 3),
          status: 'deposit',
          amount: MoneyValue(decimal: '12', currency: 'SYP'),
          reference: 'tx-safe',
        ),
      ];
      await render(WorkerDestination.depositLedger);
      expect(find.text('\u20662026-10-22 07:03 UTC\u2069'), findsOneWidget);
      expect(find.text('\u2066tx-safe\u2069'), findsOneWidget);
      expect(find.textContaining('session_assignment:'), findsNothing);
    },
  );
}
