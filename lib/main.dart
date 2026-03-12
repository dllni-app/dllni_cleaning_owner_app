import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  final navigatorKey = GlobalKey<NavigatorState>();

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
      enableNotifications: true,
      fallbackLocale: const Locale('ar'),
      startLocale: Locale('ar'),
      supportedLocales: const <Locale>[
        Locale('ar'),
        Locale('en'),
      ],
      translationsAssetPath: 'assets/translations',
      fcmTokenKey: 'fcm',
    ),
  );
}
