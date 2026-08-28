import 'dart:async';
import 'dart:ui' as ui;
import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_extension_prompts.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_global_prompt_coordinator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'core/lifecycle/background_keep_alive.dart';
import 'core/location/worker_location_tracker.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/view/screens/login_screen.dart';
import 'features/main/view/screens/main_screen.dart';

class App extends StatefulWidget {
  const App({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final CleaningWorkerGlobalPromptCoordinator _workerPromptCoordinator;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    AppForegroundGate.onResumed();
    unawaited(BackgroundKeepAlive.instance.initialize());
    final pusher = getIt<CleaningBookingPusherService>();
    unawaited(pusher.ensureInitialized());
    _workerPromptCoordinator = CleaningWorkerGlobalPromptCoordinator(
      navigatorKey: widget.navigatorKey,
    );
    CleaningWorkerExtensionPrompts.coordinator = _workerPromptCoordinator;
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        AppForegroundGate.onResumed();
        unawaited(_workerPromptCoordinator.onAppResumed());
      },
      onPause: () {
        AppForegroundGate.onPaused();
      },
      onInactive: AppForegroundGate.onInactive,
      onHide: () {
        AppForegroundGate.onHidden();
      },
    );
    unawaited(_workerPromptCoordinator.start());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    unawaited(WorkerLocationTracker.instance.stop());
    CleaningWorkerExtensionPrompts.coordinator = null;
    unawaited(_workerPromptCoordinator.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = SharedPreferencesHelper.getData(key: 'token') != null;
    return ToastificationWrapper(
      child: MaterialApp(
        navigatorKey: widget.navigatorKey,
        title: 'دللني — إدارة التنظيف',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: context.localizationDelegates,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: hasToken ? const MainScreen() : const LoginScreen(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 1.0,
            maxScaleFactor: 2.0,
          );
          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: MediaQuery(
              data: mediaQuery.copyWith(textScaler: clampedScaler),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
      ),
    );
  }
}
