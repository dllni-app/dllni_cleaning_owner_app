import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/exit_confirmation_dialog.dart';
import '../contracts/navigation.dart';

/// S00 integration seam. S01 supplies navigation visuals; feature owners supply
/// one root per tab and an authorized destination builder after WR-F reviews.
/// This host does not fetch data, authorize visits or register production routes.
typedef WorkerTabRootBuilder =
    Widget Function(BuildContext context, WorkerTab tab);

typedef WorkerIntentViewBuilder =
    Widget Function(BuildContext context, RouteIntent intent);

typedef WorkerTabBarBuilder =
    Widget Function(
      BuildContext context,
      WorkerTab selected,
      ValueChanged<WorkerTab> select,
    );

enum WorkerBackOutcome { nestedRouteHandled, returnedToToday, exitRequested }

/// Five *independent* Navigator stacks, retained while switching tabs.
///
/// Push only a previously validated, actor-authorized RouteIntent. The S00
/// composition host is responsible for worker/session membership checks,
/// cache teardown and explicit unavailable-target handling before calling
/// [openOnTab]. No route may silently fall back to another visit.
class WorkerFiveTabHost extends StatefulWidget {
  const WorkerFiveTabHost({
    super.key,
    required this.rootBuilder,
    required this.intentBuilder,
    required this.tabBarBuilder,
    this.initialTab = WorkerTab.today,
    this.onExitRequested,
  });

  final WorkerTabRootBuilder rootBuilder;
  final WorkerIntentViewBuilder intentBuilder;
  final WorkerTabBarBuilder tabBarBuilder;
  final WorkerTab initialTab;

  /// An optional integration callback for normal host/application exit.
  /// Without it, Android system back delegates to SystemNavigator.pop().
  final VoidCallback? onExitRequested;

  @override
  State<WorkerFiveTabHost> createState() => WorkerFiveTabHostState();
}

class WorkerFiveTabHostState extends State<WorkerFiveTabHost> {
  late WorkerTab _selectedTab;
  late final Map<WorkerTab, GlobalKey<NavigatorState>> _navigatorKeys;
  bool _exitConfirmationOpen = false;

  WorkerTab get selectedTab => _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _navigatorKeys = {
      for (final tab in WorkerTab.values) tab: GlobalKey<NavigatorState>(),
    };
  }

  void selectTab(WorkerTab tab) {
    if (!mounted || tab == _selectedTab) return;
    setState(() => _selectedTab = tab);
  }

  /// Caller selects the owning stack explicitly. Never infer a booking's
  /// authorized visit or turn a dispute ID into an earning key.
  Future<T?> openOnTab<T>(WorkerTab tab, RouteIntent intent) {
    final navigator = _navigatorKeys[tab]!.currentState;
    if (!mounted || navigator == null) {
      throw StateError('The requested worker tab is not mounted');
    }
    selectTab(tab);
    return navigator.push<T>(
      MaterialPageRoute<T>(
        settings: RouteSettings(name: intent.destination.id, arguments: intent),
        builder: (context) => widget.intentBuilder(context, intent),
      ),
    );
  }

  Future<WorkerBackOutcome> handleBack() async {
    final navigator = _navigatorKeys[_selectedTab]!.currentState;
    if (navigator != null && navigator.canPop()) {
      // maybePop respects route-local form-discard and other PopScope vetoes.
      await navigator.maybePop();
      return WorkerBackOutcome.nestedRouteHandled;
    }
    if (_selectedTab != WorkerTab.today) {
      selectTab(WorkerTab.today);
      return WorkerBackOutcome.returnedToToday;
    }
    return WorkerBackOutcome.exitRequested;
  }

  Future<void> _handleSystemBack() async {
    final outcome = await handleBack();
    if (outcome != WorkerBackOutcome.exitRequested || !mounted) return;
    if (widget.onExitRequested case final callback?) {
      callback();
    } else {
      // Match the existing worker home behavior: leaving the root tab must be
      // confirmed, and rapid duplicate back presses must not stack dialogs.
      if (_exitConfirmationOpen) return;
      _exitConfirmationOpen = true;
      try {
        if (await showExitConfirmationDialog(context) && mounted) {
          await SystemNavigator.pop();
        }
      } finally {
        _exitConfirmationOpen = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleSystemBack());
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab.tabIndex,
          children: [
            for (final tab in WorkerTab.values)
              // Nested stacks must not share the MaterialApp HeroController.
              HeroControllerScope.none(
                child: Navigator(
                  key: _navigatorKeys[tab],
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (context) =>
                        settings.name == Navigator.defaultRouteName
                        ? widget.rootBuilder(context, tab)
                        : const _UnavailableTabTarget(),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: widget.tabBarBuilder(
          context,
          _selectedTab,
          selectTab,
        ),
      ),
    );
  }
}

/// Unknown named routes never fall back to the tab root or another visit.
/// The reviewed composition layer can replace this with S01-localized copy.
class _UnavailableTabTarget extends StatelessWidget {
  const _UnavailableTabTarget();

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(arabic ? 'الصفحة غير متاحة' : 'Target unavailable'),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(arabic ? 'رجوع' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }
}
