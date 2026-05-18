import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_global_prompt_coordinator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'core/routes/app_router.dart';
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

  @override
  void initState() {
    super.initState();
    final pusher = getIt<CleaningBookingPusherService>();
    unawaited(pusher.ensureInitialized());
    _workerPromptCoordinator = CleaningWorkerGlobalPromptCoordinator(
      navigatorKey: widget.navigatorKey,
    );
    unawaited(_workerPromptCoordinator.start());
  }

  @override
  void dispose() {
    unawaited(_workerPromptCoordinator.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        navigatorKey: widget.navigatorKey,
        title: 'cleaning owner',
        debugShowCheckedModeBanner: false,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: SharedPreferencesHelper.getData(key: 'token') != null
            ? const MainScreen()
            : const LoginScreen(),
        theme: ThemeData(
          fontFamily: 'cairo',
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xff1E2A7B),
            onPrimary: Colors.white,
            secondary: Color(0xff6C63FF),
            onSecondary: Colors.white,
            error: Color(0xffD92341),
            onError: Colors.white,
            surface: Color(0xffF0F0F0),
            onSurface: Colors.black,
            primaryContainer: Color(0xff2EC4B6),
            onPrimaryContainer: Colors.white,
          ),
        ),
      ),
    );
  }
}
