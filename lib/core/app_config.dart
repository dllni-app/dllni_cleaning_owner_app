import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  /// When true, start travel is only allowed within one hour of the scheduled time.
  /// Disabled in debug builds; enabled in release. Override with
  /// `--dart-define=ENFORCE_START_TRAVEL_WINDOW=true|false`.
  static const bool enforceStartTravelWindow = bool.fromEnvironment(
    'ENFORCE_START_TRAVEL_WINDOW',
    defaultValue: false,
  );

  static const String appName = 'cleaning owner';  static const String orgIdentifier = 'com.dllni.clOwner';
  static const String baseUrl = 'https://alnadha.net';

  /// https://alnadha.net
  /// https://dllni.mustafafares.com
  /// Pusher public key (same as Laravel `PUSHER_APP_KEY`). Override with
  /// `--dart-define=PUSHER_APP_KEY=...` or legacy `--dart-define=PUSHER_KEY=...`.
  ///
  /// **Never** put `PUSHER_APP_SECRET` in the mobile app — it belongs only in backend `.env`.
  static const String pusherKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: String.fromEnvironment(
      'PUSHER_KEY',
      defaultValue: 'e85e7756c1171baaa471',
    ),
  );
  static const String pusherCluster = String.fromEnvironment(
    'PUSHER_APP_CLUSTER',
    defaultValue: String.fromEnvironment('PUSHER_CLUSTER', defaultValue: 'eu'),
  );

  /// Same as Laravel `PUSHER_APP_ID` (optional; not required by the Pusher client).
  static const String pusherAppId = String.fromEnvironment(
    'PUSHER_APP_ID',
    defaultValue: '2120839',
  );
}
