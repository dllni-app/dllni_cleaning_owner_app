import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/integration/five_tab_host.dart';

Widget _tabBar(
  BuildContext context,
  WorkerTab selected,
  ValueChanged<WorkerTab> select,
) {
  return Row(
    children: [
      for (final tab in WorkerTab.values)
        Expanded(
          child: TextButton(
            key: ValueKey('tab-${tab.name}'),
            onPressed: () => select(tab),
            child: Text(tab.name),
          ),
        ),
    ],
  );
}

class _PersistentRoot extends StatefulWidget {
  const _PersistentRoot(this.tab);
  final WorkerTab tab;

  @override
  State<_PersistentRoot> createState() => _PersistentRootState();
}

class _PersistentRootState extends State<_PersistentRoot> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('root:${widget.tab.name}'),
          Text('count:$_counter'),
          TextButton(
            key: ValueKey('increment-${widget.tab.name}'),
            onPressed: () => setState(() => _counter++),
            child: const Text('increment'),
          ),
          TextButton(
            key: ValueKey('unknown-${widget.tab.name}'),
            onPressed: () => Navigator.of(context).pushNamed('/unknown-target'),
            child: const Text('unknown target'),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('five independent stacks retain tab-local page state', (
    tester,
  ) async {
    final key = GlobalKey<WorkerFiveTabHostState>();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerFiveTabHost(
          key: key,
          rootBuilder: (_, tab) => _PersistentRoot(tab),
          intentBuilder: (_, intent) => Text(intent.destination.id),
          tabBarBuilder: _tabBar,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('increment-today')));
    await tester.pump();
    expect(find.text('root:today'), findsOneWidget);
    expect(find.text('count:1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-jobs')));
    await tester.pumpAndSettle();
    expect(key.currentState!.selectedTab, WorkerTab.jobs);
    expect(find.text('root:jobs'), findsOneWidget);
    expect(find.text('count:0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('increment-jobs')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('tab-today')));
    await tester.pumpAndSettle();
    expect(find.text('root:today'), findsOneWidget);
    expect(find.text('count:1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-jobs')));
    await tester.pumpAndSettle();
    expect(find.text('count:1'), findsOneWidget);
  });

  testWidgets(
    'pushed scoped visit survives navigation, then back returns Today',
    (tester) async {
      final key = GlobalKey<WorkerFiveTabHostState>();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerFiveTabHost(
            key: key,
            rootBuilder: (_, tab) => _PersistentRoot(tab),
            intentBuilder: (_, intent) => Scaffold(
              body: Text(
                'booking=${intent.scope!.bookingId},session=${intent.scope!.sessionId}',
              ),
            ),
            tabBarBuilder: _tabBar,
          ),
        ),
      );
      final exactVisit = RouteIntent(
        destination: WorkerDestination.mission,
        origin: RouteOrigin.schedule,
        scope: WorkScope(bookingId: '101', sessionId: '202'),
      );
      unawaited(
        key.currentState!.openOnTab<void>(WorkerTab.schedule, exactVisit),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.selectedTab, WorkerTab.schedule);
      expect(find.text('booking=101,session=202'), findsOneWidget);

      expect(
        await key.currentState!.handleBack(),
        WorkerBackOutcome.nestedRouteHandled,
      );
      await tester.pumpAndSettle();
      expect(find.text('root:schedule'), findsOneWidget);
      expect(
        await key.currentState!.handleBack(),
        WorkerBackOutcome.returnedToToday,
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.selectedTab, WorkerTab.today);
      expect(
        await key.currentState!.handleBack(),
        WorkerBackOutcome.exitRequested,
      );
    },
  );

  testWidgets('a guarded nested route is not bypassed by shell back', (
    tester,
  ) async {
    final key = GlobalKey<WorkerFiveTabHostState>();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerFiveTabHost(
          key: key,
          rootBuilder: (_, tab) => _PersistentRoot(tab),
          intentBuilder: (_, intent) => const PopScope(
            canPop: false,
            child: Scaffold(body: Text('unsaved form')),
          ),
          tabBarBuilder: _tabBar,
        ),
      ),
    );
    unawaited(
      key.currentState!.openOnTab<void>(
        WorkerTab.account,
        RouteIntent(
          destination: WorkerDestination.profileEdit,
          origin: RouteOrigin.profile,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('unsaved form'), findsOneWidget);
    expect(
      await key.currentState!.handleBack(),
      WorkerBackOutcome.nestedRouteHandled,
    );
    await tester.pumpAndSettle();
    expect(find.text('unsaved form'), findsOneWidget);
    expect(key.currentState!.selectedTab, WorkerTab.account);
  });

  testWidgets('unknown nested names fail closed instead of rendering a tab', (
    tester,
  ) async {
    final key = GlobalKey<WorkerFiveTabHostState>();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerFiveTabHost(
          key: key,
          rootBuilder: (_, tab) => _PersistentRoot(tab),
          intentBuilder: (_, intent) => Text(intent.destination.id),
          tabBarBuilder: _tabBar,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('unknown-today')));
    await tester.pumpAndSettle();
    expect(find.text('Target unavailable'), findsOneWidget);
    expect(find.text('root:today'), findsNothing);
    expect(
      await key.currentState!.handleBack(),
      WorkerBackOutcome.nestedRouteHandled,
    );
    await tester.pumpAndSettle();
    expect(find.text('root:today'), findsOneWidget);
  });

  testWidgets('root system back requires exit confirmation and can stay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkerFiveTabHost(
          rootBuilder: (_, tab) => _PersistentRoot(tab),
          intentBuilder: (_, intent) => Text(intent.destination.id),
          tabBarBuilder: _tabBar,
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.text('هل أنت متأكد من رغبتك في الخروج من التطبيق؟'),
      findsOneWidget,
    );
    expect(find.text('root:today'), findsOneWidget);

    await tester.tap(find.text('البقاء'));
    await tester.pumpAndSettle();
    expect(
      find.text('هل أنت متأكد من رغبتك في الخروج من التطبيق؟'),
      findsNothing,
    );
    expect(find.text('root:today'), findsOneWidget);
  });
}
