# Notification Helper Usage

This file shows how to use `NotificationHelper` after the refactor.

## 1) Initialize in app startup

Call `NotificationHelper.initAllNotifications` once (for example in `main.dart`) and pass:
- your FCM token storage key
- your app `navigatorKey`
- optional tap callbacks for each app lifecycle state
- optional route argument mapper

```dart
import 'package:common_package/helpers/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> setupNotifications() async {
  await NotificationHelper.initAllNotifications(
    tokenKey: 'fcm_token',
    navigatorKey: navigatorKey,
    onTerminatedTap: _onTerminatedTap,
    onBackgroundTap: _onBackgroundTap,
    onForegroundTap: _onForegroundTap,
    routeArgumentsBuilder: _routeArgumentsBuilder,
  );
}

Future<void> _onTerminatedTap(RemoteMessage message) async {
  // Runs when app was opened from a terminated state by a notification tap.
}

Future<void> _onBackgroundTap(RemoteMessage message) async {
  // Runs when app was in background and user tapped notification.
}

Future<void> _onForegroundTap(RemoteMessage message) async {
  // Runs when notification action is tapped while app is foreground.
}

Object? _routeArgumentsBuilder(String route, Map<String, dynamic> argsMap) {
  // Optional: convert payload map into your generated route argument objects.
  if (argsMap.containsKey('arguments')) {
    return argsMap['arguments'];
  }
  return argsMap.isEmpty ? null : argsMap;
}
```

## 2) Attach navigatorKey to MaterialApp

```dart
MaterialApp(
  navigatorKey: navigatorKey,
  onGenerateRoute: GeneratedAppRoutes.onGenerateRoute,
);
```

## 3) Notification payload contract

The helper expects notification route data in `message.data['args']` as JSON string.

Required:
- `route`: route name/path handled by your `GeneratedAppRoutes.onGenerateRoute`

Optional:
- `arguments`: explicit argument object/map to pass to route
- any additional keys used by your custom `routeArgumentsBuilder`

Example payload:

```json
{
  "args": "{\"route\":\"/orders\",\"arguments\":{\"orderId\":123}}"
}
```

## 4) Navigation behavior

- Helper auto-navigates first using `route_extensions.dart` (`context.pushRoute(...)`).
- Then it calls the matching callback (`onTerminatedTap`, `onBackgroundTap`, or `onForegroundTap`).
- If route parsing fails or context is unavailable, callback still runs.

## 5) Dedup behavior

The helper has a short dedup window to avoid double handling when both FCM and Awesome events fire for the same tap.
