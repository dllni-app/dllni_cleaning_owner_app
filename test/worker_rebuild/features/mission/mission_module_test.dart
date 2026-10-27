import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/ports.dart'
    as worker_ports;
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/design_system/design_system.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/features/mission/module.dart';

import 'mission_fixtures.dart';

Widget harness(
  FakeMissionPort port, {
  WorkScope? scope,
  WorkerSessionContext? session,
  FakeRuntime? runtime,
  List<WorkScope> visits = const [],
  String language = 'en',
  double textScale = 1,
  ValueChanged<RouteIntent>? onRoute,
}) => MaterialApp(
  theme: WorkerV2Theme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: MissionModule(
    session: session ?? fixtureSession,
    scope: scope ?? firstVisit,
    missionPort: port,
    runtime: runtime ?? FakeRuntime(),
    authorizedVisitScopes: visits,
    onRoute: onRoute ?? (_) {},
    languageCode: language,
  ),
);

Future<void> tapVisible(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// The mission page scrolls its header with its content. Return the refresh
/// icon to the viewport before tapping it after a deeply scrolled interaction.
Future<void> refreshVisible(
  WidgetTester tester, {
  bool awaitCompletion = true,
}) async {
  final refresh = find.byIcon(Icons.refresh);
  await tester.ensureVisible(refresh);
  await tester.pumpAndSettle();
  await tester.tap(refresh);
  if (awaitCompletion) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void expectSosDisabled(WidgetTester tester) {
  final action = find.ancestor(
    of: find.text('Emergency assistance'),
    matching: find.byType(WrActionButton),
  );
  expect(action, findsOneWidget);
  expect(tester.widget<WrActionButton>(action).onPressed, isNull);
}

void main() {
  testWidgets('future scheduled mission does not route SOS before its window', (
    tester,
  ) async {
    final routes = <RouteIntent>[];
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        scheduledStartsAt: DateTime.now().toUtc().add(const Duration(days: 2)),
        actions: {WorkerAction.sendSos},
      ),
    });
    await tester.pumpWidget(harness(port, onRoute: routes.add));
    await tester.pumpAndSettle();
    expect(find.text('Emergency assistance'), findsNothing);
    expect(routes, isEmpty);
  });

  testWidgets(
    'supervisor execution lock retains independent attendance and SOS scope',
    (tester) async {
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(
          firstVisit,
          execution: false,
          owner: ExecutionOwner.supervisor,
          actions: {
            WorkerAction.startTravel,
            WorkerAction.sendSos,
            WorkerAction.confirmWorkStart,
            WorkerAction.submitCompletion,
          },
        ),
      });
      final routes = <RouteIntent>[];
      await tester.pumpWidget(harness(port, onRoute: routes.add));
      await tester.pumpAndSettle();
      expect(
        find.text('Execution is unavailable for this visit'),
        findsOneWidget,
      );
      await tapVisible(tester, 'Start travelling');
      expect(port.submitted, hasLength(1));
      expect(port.submitted.single, isA<SimpleMissionCommand>());
      expect(
        (port.submitted.single as SimpleMissionCommand).action,
        SimpleMissionAction.startTravel,
      );
      expect(port.submitted.single.scope.cacheKey, firstVisit.cacheKey);
      await tapVisible(tester, 'Emergency assistance');
      expect(routes.single.destination, WorkerDestination.sos);
      expect(routes.single.scope!.cacheKey, firstVisit.cacheKey);
      await tapVisible(tester, 'Support');
      expect(routes.last.destination, WorkerDestination.support);
      expect(routes.last.scope!.cacheKey, firstVisit.cacheKey);
      await tester.ensureVisible(find.text('Request work start'));
      await tester.tap(find.text('Request work start'), warnIfMissed: false);
      expect(port.submitted, hasLength(1));
    },
  );

  testWidgets('selecting an authorized sibling resets all scope-bound data', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        customerLocation: 'AREA-ONE',
      ),
      secondVisit.cacheKey: fixtureMission(
        secondVisit,
        customerLocation: 'AREA-TWO',
      ),
    });
    await tester.pumpWidget(harness(port, visits: [firstVisit, secondVisit]));
    await tester.pumpAndSettle();
    expect(find.text('AREA-ONE'), findsOneWidget);
    await tapVisible(tester, 'visit-two');
    expect(port.requested.last.cacheKey, secondVisit.cacheKey);
    expect(find.text('AREA-ONE'), findsNothing);
    expect(find.text('AREA-TWO'), findsOneWidget);
  });

  testWidgets(
    'forbidden mission revokes scoped SOS but generic support has no scope',
    (tester) async {
      final routes = <RouteIntent>[];
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(
          firstVisit,
          actions: {WorkerAction.sendSos},
          customerLocation: 'FIRST-WORKER-PRIVATE-LOCATION',
        ),
      });
      await tester.pumpWidget(harness(port, onRoute: routes.add));
      await tester.pumpAndSettle();
      expect(find.text('FIRST-WORKER-PRIVATE-LOCATION'), findsOneWidget);
      expect(
        tester
            .widget<WrActionButton>(
              find.ancestor(
                of: find.text('Emergency assistance'),
                matching: find.byType(WrActionButton),
              ),
            )
            .onPressed,
        isNotNull,
      );

      port.readFailure = PortFailure(
        kind: FailureKind.forbidden,
        reasonCode: 'assignment_revoked',
      );
      await refreshVisible(tester);
      expect(find.text('FIRST-WORKER-PRIVATE-LOCATION'), findsNothing);
      expect(
        find.text('You are not permitted to view this visit'),
        findsOneWidget,
      );
      expectSosDisabled(tester);
      expect(routes, isEmpty);
      await tapVisible(tester, 'Support');
      expect(routes, hasLength(1));
      expect(routes.single.destination, WorkerDestination.support);
      expect(routes.single.scope, isNull);
    },
  );

  testWidgets(
    'missing mission cannot route SOS or leak scope through support',
    (tester) async {
      final routes = <RouteIntent>[];
      final port = FakeMissionPort({});
      await tester.pumpWidget(harness(port, onRoute: routes.add));
      await tester.pumpAndSettle();
      expect(
        find.text('This visit is unavailable or no longer assigned'),
        findsOneWidget,
      );
      expectSosDisabled(tester);
      await tapVisible(tester, 'Support');
      expect(routes.single.destination, WorkerDestination.support);
      expect(routes.single.scope, isNull);
    },
  );

  testWidgets(
    'fresh mission without explicit SOS grant cannot route emergency',
    (tester) async {
      final routes = <RouteIntent>[];
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(
          firstVisit,
          actions: {WorkerAction.view},
        ),
      });
      await tester.pumpWidget(harness(port, onRoute: routes.add));
      await tester.pumpAndSettle();
      expectSosDisabled(tester);
      expect(routes, isEmpty);
      await tapVisible(tester, 'Support');
      expect(routes.single.scope!.cacheKey, firstVisit.cacheKey);
    },
  );

  testWidgets(
    'same-scope worker A to B switch clears old mission before fresh B read',
    (tester) async {
      final routes = <RouteIntent>[];
      final runtime = FakeRuntime();
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(
          firstVisit,
          actions: {WorkerAction.sendSos},
          customerLocation: 'WORKER-A-CONFIDENTIAL',
        ),
      });
      await tester.pumpWidget(
        harness(port, runtime: runtime, onRoute: routes.add),
      );
      await tester.pumpAndSettle();
      expect(find.text('WORKER-A-CONFIDENTIAL'), findsOneWidget);

      // Keep the same scope, runtime object, and port to isolate the identity
      // transition itself. Worker B's read is deliberately held in flight.
      final workerB = WorkerSessionContext(
        userId: 'other-user',
        workerId: 'other-worker',
        generation: 'other-generation',
      );
      final pendingB = Completer<ReadResult<MissionView>>();
      port.delayed[firstVisit.cacheKey] = pendingB;
      runtime.contextValue = workerB;
      await tester.pumpWidget(
        harness(port, runtime: runtime, session: workerB, onRoute: routes.add),
      );
      await tester.pump();
      expect(find.text('WORKER-A-CONFIDENTIAL'), findsNothing);
      expect(find.text('Loading visit details'), findsOneWidget);
      expectSosDisabled(tester);
      // Avoid pumpAndSettle while the intentionally held loading spinner animates.
      await tester.ensureVisible(find.text('Support'));
      await tester.pump();
      await tester.tap(find.text('Support'));
      await tester.pump();
      expect(routes.single.destination, WorkerDestination.support);
      expect(routes.single.scope, isNull);

      pendingB.complete(
        fresh(
          fixtureMission(
            firstVisit,
            actions: {WorkerAction.sendSos},
            customerLocation: 'WORKER-B-ONLY',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('WORKER-A-CONFIDENTIAL'), findsNothing);
      expect(find.text('WORKER-B-ONLY'), findsOneWidget);
      expect(
        tester
            .widget<WrActionButton>(
              find.ancestor(
                of: find.text('Emergency assistance'),
                matching: find.byType(WrActionButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('stale first visit result cannot overwrite selected second visit', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(firstVisit, customerLocation: 'ST-A'),
      secondVisit.cacheKey: fixtureMission(
        secondVisit,
        customerLocation: 'ST-B',
      ),
    });
    await tester.pumpWidget(harness(port, visits: [firstVisit, secondVisit]));
    await tester.pumpAndSettle();
    final pending = Completer<ReadResult<MissionView>>();
    port.delayed[firstVisit.cacheKey] = pending;
    await refreshVisible(tester, awaitCompletion: false);
    // Navigation comes from a new canonical route argument while old HTTP is pending.
    await tester.pumpWidget(
      harness(port, scope: secondVisit, visits: [firstVisit, secondVisit]),
    );
    await tester.pumpAndSettle();
    pending.complete(
      fresh(fixtureMission(firstVisit, customerLocation: 'OLD-RESPONSE')),
    );
    await tester.pumpAndSettle();
    expect(find.text('OLD-RESPONSE'), findsNothing);
    expect(find.text('ST-B'), findsOneWidget);
  });

  testWidgets('cross-scope payload is rejected and private fields are hidden', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        secondVisit,
        customerLocation: 'PRIVATE',
      ),
    });
    await tester.pumpWidget(harness(port));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE'), findsNothing);
    expect(
      find.text('You are not permitted to view this visit'),
      findsOneWidget,
    );
    expect(find.text('Start travelling'), findsNothing);
    expect(port.submitted, isEmpty);
  });

  testWidgets(
    'secondary endpoint revocation removes previously authorized scope',
    (tester) async {
      final routes = <RouteIntent>[];
      final port =
          FakeMissionPort({
              firstVisit.cacheKey: fixtureMission(
                firstVisit,
                actions: {WorkerAction.sendSos},
                customerLocation: 'HIDDEN-AFTER-403',
              ),
            })
            ..inventoryFailure = PortFailure(
              kind: FailureKind.forbidden,
              reasonCode: 'assignment_revoked',
            );
      await tester.pumpWidget(harness(port, onRoute: routes.add));
      await tester.pumpAndSettle();
      expect(find.text('HIDDEN-AFTER-403'), findsNothing);
      expect(
        find.text('You are not permitted to view this visit'),
        findsOneWidget,
      );
      expectSosDisabled(tester);
      await tapVisible(tester, 'Support');
      expect(routes.single.destination, WorkerDestination.support);
      expect(routes.single.scope, isNull);
    },
  );

  testWidgets(
    'code is fetched only on explicit permitted reveal and never entered',
    (tester) async {
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(
          firstVisit,
          actions: {WorkerAction.viewVerificationCode},
          customerPhone: 'SECRET-PHONE-DO-NOT-DISPLAY',
        ),
      });
      await tester.pumpWidget(harness(port));
      await tester.pumpAndSettle();
      expect(port.verificationReads, 0);
      expect(find.text('SECRET-PHONE-DO-NOT-DISPLAY'), findsNothing);
      expect(find.text('DEMO-CODE'), findsNothing);
      await tapVisible(tester, 'Show authorized code');
      expect(port.verificationReads, 1);
      expect(find.text('DEMO-CODE'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await refreshVisible(tester);
      expect(find.text('DEMO-CODE'), findsNothing);
    },
  );

  testWidgets('local checklist never submits a mission mutation', (
    tester,
  ) async {
    final port = FakeMissionPort({
      bookingScope.cacheKey: fixtureMission(bookingScope),
    });
    await tester.pumpWidget(harness(port, scope: bookingScope));
    await tester.pumpAndSettle();
    final draft = find.byKey(const ValueKey('service_draft_0'));
    await tester.ensureVisible(draft);
    await tester.tap(draft);
    await tester.pump();
    expect(find.text('Reviewed locally'), findsOneWidget);
    expect(port.submitted, isEmpty);
    await tester.ensureVisible(find.text('Submit completion report'));
    await tester.tap(
      find.text('Submit completion report'),
      warnIfMissed: false,
    );
    expect(
      port.submitted,
      isEmpty,
    ); // No stable legacy snapshot identity supplied.
  });

  testWidgets('special-service duplicate labels retain distinct line IDs', (
    tester,
  ) async {
    final lines = ['line-A', 'line-B']
        .map(
          (id) => MissionServiceLineView(
            scope: firstVisit,
            lineId: id,
            label: 'Window service',
            status: 'pending',
            allowedActions: {WorkerAction.startSpecialService},
          ),
        )
        .toList();
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        actions: {WorkerAction.startSpecialService},
        serviceLines: lines,
      ),
    });
    await tester.pumpWidget(harness(port));
    await tester.pumpAndSettle();
    expect(find.text('Window service'), findsNWidgets(2));
    final buttons = find.text('Start service');
    await tester.ensureVisible(buttons.last);
    await tester.pump();
    await tester.tap(buttons.last);
    await tester.pumpAndSettle();
    expect(port.submitted.single, isA<SpecialServiceStartCommand>());
    expect(
      (port.submitted.single as SpecialServiceStartCommand).lineId,
      'line-B',
    );
  });

  testWidgets(
    'equipment custody uses reservation identity and excludes missing IDs',
    (tester) async {
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(
          firstVisit,
          actions: {WorkerAction.acknowledgeEquipment},
        ),
      });
      port.inventories[firstVisit.cacheKey] = InventoryView(
        scope: firstVisit,
        items: [
          InventoryItemView(
            itemId: 'item-1',
            reservationId: 'reservation-1',
            name: 'Vacuum',
            quantity: '1',
            custodyState: 'issued',
            allowedActions: {WorkerAction.acknowledgeEquipment},
          ),
          InventoryItemView(
            itemId: 'item-2',
            name: 'Mop',
            quantity: '1',
            custodyState: 'issued',
            allowedActions: {WorkerAction.acknowledgeEquipment},
          ),
        ],
      );
      await tester.pumpWidget(harness(port));
      await tester.pumpAndSettle();
      expect(find.text('Acknowledge equipment'), findsOneWidget);
      await tapVisible(tester, 'Acknowledge equipment');
      expect(port.submitted.single, isA<AcknowledgeEquipmentCommand>());
      expect(
        (port.submitted.single as AcknowledgeEquipmentCommand).reservationId,
        'reservation-1',
      );
    },
  );

  testWidgets('extension decision retains exact record family and visit', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        actions: {WorkerAction.acceptExtension},
      ),
    });
    port.decisions[firstVisit.cacheKey] = [
      DecisionView(
        requestId: 'fixed-warning-id',
        scope: firstVisit,
        kind: 'extension',
        status: 'pending',
        decisionActor: 'worker',
        extensionFamily: ExtensionRecordFamily.fixedTimeWarning,
        currentValues: {'minutes': '30'},
        proposedValues: {'minutes': '45'},
        pricedAmount: MoneyValue(decimal: '0.00', currency: 'SYP'),
      ),
    ];
    await tester.pumpWidget(harness(port));
    await tester.pumpAndSettle();
    expect(find.text('0.00 SYP'), findsOneWidget);
    await tapVisible(tester, 'Approve');
    final sheetApprove = find.descendant(
      of: find.descendant(
        of: find.byType(WrSheetFrame),
        matching: find.byType(WrActionButton),
      ),
      matching: find.text('Approve'),
    );
    expect(sheetApprove, findsOneWidget);
    await tester.ensureVisible(sheetApprove);
    await tester.pumpAndSettle();
    await tester.tap(sheetApprove);
    await tester.pumpAndSettle();
    expect(port.submitted.single, isA<ExtensionDecisionCommand>());
    final command = port.submitted.single as ExtensionDecisionCommand;
    expect(command.scope.cacheKey, firstVisit.cacheKey);
    expect(command.family, ExtensionRecordFamily.fixedTimeWarning);
    expect(command.extensionId, 'fixed-warning-id');
    expect(command.additionalMinutes, isNull);
  });

  testWidgets('unknown command outcome re-reads before new action can proceed', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        actions: {WorkerAction.startTravel},
      ),
    })..commandStatus = CommandStatus.outcomeUnknown;
    await tester.pumpWidget(harness(port));
    await tester.pumpAndSettle();
    final initialReads = port.fetchCount;
    await tapVisible(tester, 'Start travelling');
    expect(port.submitted, hasLength(1));
    expect(port.fetchCount, greaterThan(initialReads));
    // The toolchain must never automatically retry the potentially committed POST.
    expect(port.submitted, hasLength(1));
  });

  testWidgets('a pending mutation is single-flight even under repeated taps', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        actions: {WorkerAction.startTravel},
      ),
    })..delayedCommand = Completer<CommandResult>();
    await tester.pumpWidget(harness(port));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start travelling'));
    await tester.tap(find.text('Start travelling'));
    await tester.pump();
    await tester.tap(find.text('Start travelling'), warnIfMissed: false);
    expect(port.submitted, hasLength(1));
    port.delayedCommand!.complete(
      CommandResult(status: CommandStatus.confirmed),
    );
    await tester.pumpAndSettle();
    expect(port.submitted, hasLength(1));
  });

  testWidgets('missing extension family never creates a response command', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        actions: {WorkerAction.acceptExtension, WorkerAction.rejectExtension},
      ),
    });
    port.decisions[firstVisit.cacheKey] = [
      DecisionView(
        requestId: 'ambiguous-family',
        scope: firstVisit,
        kind: 'extension',
        status: 'pending',
        decisionActor: 'worker',
        currentValues: {},
        proposedValues: {},
      ),
    ];
    await tester.pumpWidget(harness(port));
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(port.submitted, isEmpty);
  });

  testWidgets('stale reads never grant fresh-action permission', (
    tester,
  ) async {
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        actions: {WorkerAction.startTravel},
      ),
    })..freshness = ReadFreshness.stale;
    await tester.pumpWidget(harness(port));
    await tester.pumpAndSettle();
    expect(
      find.text('This view is stale. Refresh before taking action'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Start travelling'));
    await tester.tap(find.text('Start travelling'), warnIfMissed: false);
    expect(port.submitted, isEmpty);
  });

  testWidgets('revoked runtime identity immediately conceals the active view', (
    tester,
  ) async {
    final runtime = FakeRuntime();
    final port = FakeMissionPort({
      firstVisit.cacheKey: fixtureMission(
        firstVisit,
        actions: {WorkerAction.sendSos},
        customerLocation: 'AUTHORIZED-AREA',
      ),
    });
    await tester.pumpWidget(harness(port, runtime: runtime));
    await tester.pumpAndSettle();
    expect(find.text('AUTHORIZED-AREA'), findsOneWidget);
    runtime.phaseValue = worker_ports.RuntimePhase.revoked;
    await tester.pumpWidget(harness(port, runtime: runtime));
    await tester.pump();
    expect(find.text('AUTHORIZED-AREA'), findsNothing);
    expect(find.text('Session expired. Sign in again'), findsOneWidget);
    expectSosDisabled(tester);
    final support = find.ancestor(
      of: find.text('Support'),
      matching: find.byType(WrActionButton),
    );
    expect(tester.widget<WrActionButton>(support).onPressed, isNull);
  });

  testWidgets(
    'offline/stale/forbidden deny commands; unavailable visits hide data',
    (tester) async {
      final runtime = FakeRuntime()
        ..connectionValue = worker_ports.ConnectionState.offline;
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(
          firstVisit,
          actions: {WorkerAction.startTravel},
        ),
      });
      await tester.pumpWidget(harness(port, runtime: runtime));
      await tester.pumpAndSettle();
      expect(find.text('Offline: read-only view'), findsOneWidget);
      await tester.ensureVisible(find.text('Start travelling'));
      await tester.tap(find.text('Start travelling'), warnIfMissed: false);
      expect(port.submitted, isEmpty);

      port.readFailure = PortFailure(
        kind: FailureKind.forbidden,
        reasonCode: 'denied',
      );
      runtime.connectionValue = worker_ports.ConnectionState.online;
      await refreshVisible(tester);
      expect(
        find.text('You are not permitted to view this visit'),
        findsOneWidget,
      );
      expect(find.text('Start travelling'), findsNothing);
    },
  );

  testWidgets(
    'Arabic RTL at narrow high text scale retains actions and scroll',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1300);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = FakeMissionPort({
        firstVisit.cacheKey: fixtureMission(firstVisit),
      });
      await tester.pumpWidget(harness(port, language: 'ar', textScale: 2));
      await tester.pumpAndSettle();
      expect(find.text('مساحة المهمة'), findsOneWidget);
      expect(find.text('طلب مساعدة طارئة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
