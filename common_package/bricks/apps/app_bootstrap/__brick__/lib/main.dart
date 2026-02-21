import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  final navigatorKey = GlobalKey<NavigatorState>();

  await bootstrapApp(
    AppBootstrapConfig(
      navigatorKey: navigatorKey,
      app: App(navigatorKey: navigatorKey),
      configureDependencies: configureDependencies,
      enableNotifications: {{enable_notifications}},
      fallbackLocale: const Locale('{{default_locale}}'),
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('ar'),
      ],
      translationsAssetPath: 'assets/translations',
      fcmTokenKey: 'fcm_token',
    ),
  );
}
