import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'notification_helper.dart';
import 'shared_preferences_helper.dart';

class AppBootstrapConfig {
  AppBootstrapConfig({
    required this.navigatorKey,
    required this.app,
    required this.configureDependencies,
    this.enableNotifications = true,
    this.fcmTokenKey = 'fcm_token',
    this.supportedLocales = const [Locale('en'), Locale('ar')],
    this.fallbackLocale = const Locale('en'),
    this.translationsAssetPath = 'assets/translations',
    this.startLocale,
    this.onTerminatedTap,
    this.onBackgroundTap,
    this.onForegroundTap,
    this.routeArgumentsBuilder,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget app;
  final Future<void> Function() configureDependencies;
  final bool enableNotifications;
  final String fcmTokenKey;
  final List<Locale> supportedLocales;
  final Locale fallbackLocale;
  final String translationsAssetPath;
  final Locale? startLocale;
  final NotificationTapCallback? onTerminatedTap;
  final NotificationTapCallback? onBackgroundTap;
  final NotificationTapCallback? onForegroundTap;
  final NotificationRouteArgumentsBuilder? routeArgumentsBuilder;
}

Future<void> bootstrapApp(AppBootstrapConfig config) async {
  if (config.supportedLocales.isEmpty) {
    throw ArgumentError.value(
      config.supportedLocales,
      'supportedLocales',
      'must not be empty',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SharedPreferencesHelper.init();
  await config.configureDependencies();

  if (config.enableNotifications) {
    await NotificationHelper.initAllNotifications(
      tokenKey: config.fcmTokenKey,
      navigatorKey: config.navigatorKey,
      onTerminatedTap: config.onTerminatedTap,
      onBackgroundTap: config.onBackgroundTap,
      onForegroundTap: config.onForegroundTap,
      routeArgumentsBuilder: config.routeArgumentsBuilder,
    );
  }

  runApp(
    EasyLocalization(
      supportedLocales: config.supportedLocales,
      fallbackLocale: config.fallbackLocale,
      startLocale: config.startLocale,
      path: config.translationsAssetPath,
      child: config.app,
    ),
  );
}
