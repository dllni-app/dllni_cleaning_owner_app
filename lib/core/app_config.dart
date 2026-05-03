class AppConfig {
  const AppConfig._();

  static const String appName = 'cleaning owner';
  static const String orgIdentifier = 'com.dllni.clOwner';
  static const String baseUrl = 'https://dllni.mustafafares.com';

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
    defaultValue: String.fromEnvironment(
      'PUSHER_CLUSTER',
      defaultValue: 'eu',
    ),
  );

  /// Same as Laravel `PUSHER_APP_ID` (optional; not required by the Pusher client).
  static const String pusherAppId = String.fromEnvironment(
    'PUSHER_APP_ID',
    defaultValue: '2120839',
  );
}
