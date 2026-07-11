import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/logging/app_debug_logger.dart';
import 'core/notifications/fcm_token_registrar.dart';
import 'core/session/session_expired_handler.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await AppDebugLogger.init();

      Intl.defaultLocale = 'en';
      final navigatorKey = GlobalKey<NavigatorState>();
      SessionExpiredHandler.navigatorKey = navigatorKey;
      AppToast.bindNavigatorKey(navigatorKey);

      await bootstrapApp(
        AppBootstrapConfig(
          navigatorKey: navigatorKey,
          app: ScreenUtilPlusInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => App(navigatorKey: navigatorKey),
          ),
          configureDependencies: configureInjection,
          enableNotifications: false,
          startLocale: Locale('ar'),
          fallbackLocale: const Locale('ar'),
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          translationsAssetPath: 'assets/translations',
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          NotificationHelper.initAllNotifications(
            tokenKey: 'fcm',
            navigatorKey: navigatorKey,
            onFcmTokenAvailable: FcmTokenRegistrar.registerIfAuthenticated,
          ),
        );
      });
    },
    (error, stackTrace) {
      AppDebugLogger.recordError('UNCAUGHT', error, stackTrace);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        AppDebugLogger.recordPrint(line);
        parent.print(zone, line);
      },
    ),
  );
}
