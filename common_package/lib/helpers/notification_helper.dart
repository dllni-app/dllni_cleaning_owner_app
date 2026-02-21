import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:common_package/extensions/route_extensions.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef NotificationTapCallback = FutureOr<void> Function(RemoteMessage message);
typedef NotificationRouteArgumentsBuilder = Object? Function(String route, Map<String, dynamic> argsMap);

class _ResolvedRoute {
  final String route;
  final Object? arguments;

  const _ResolvedRoute({required this.route, this.arguments});
}

const String _lifecycleMarkerKey = '_notification_lifecycle';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final payload = message.data.map((k, v) => MapEntry(k.toString(), v.toString()));
  // Store lifecycle marker to indicate this notification was created in background
  payload[_lifecycleMarkerKey] = NotificationLifeCycle.Background.name;

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'basic_channel',
      title: message.notification?.title ?? message.data['title'] ?? 'New Notification',
      body: message.notification?.body ?? message.data['body'] ?? '',
      payload: payload,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  log('Notification clicked: ${action.payload}');
  await NotificationHelper.handleAwesomeAction(action);
}

class NotificationHelper {
  NotificationHelper._();

  static final NotificationHelper _instance = NotificationHelper._();

  factory NotificationHelper() => _instance;

  static final AwesomeNotifications _awesome = AwesomeNotifications();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static NotificationTapCallback? _onTerminatedTap;
  static NotificationTapCallback? _onBackgroundTap;
  static NotificationTapCallback? _onForegroundTap;
  static NotificationRouteArgumentsBuilder? _routeArgumentsBuilder;

  static String? _lastTapFingerprint;
  static DateTime? _lastTapAt;
  static const Duration _tapDedupDuration = Duration(seconds: 3);

  static Future<void> initAllNotifications({
    required String tokenKey,
    required GlobalKey<NavigatorState> navigatorKey,
    NotificationTapCallback? onTerminatedTap,
    NotificationTapCallback? onBackgroundTap,
    NotificationTapCallback? onForegroundTap,
    NotificationRouteArgumentsBuilder? routeArgumentsBuilder,
  }) async {
    _navigatorKey = navigatorKey;
    _onTerminatedTap = onTerminatedTap;
    _onBackgroundTap = onBackgroundTap;
    _onForegroundTap = onForegroundTap;
    _routeArgumentsBuilder = routeArgumentsBuilder;

    await _initFirebase(tokenKey);
    await _initAwesomeNotifications();
    await _ensurePermission();
    _registerListeners();
    await _checkTerminatedNotification();
    await _startAwesomeListeners();
    await _checkInitialAwesomeAction();
  }

  static Future<void> _initFirebase(String tokenKey) async {
    await Firebase.initializeApp();
    await getToken(tokenKey);
  }

  static Future<void> getToken(String tokenKey) async {
    final token = Platform.isIOS ? await FirebaseMessaging.instance.getAPNSToken() : await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await SharedPreferencesHelper.saveData(key: tokenKey, value: token);
      log('FCM Token: $token');
    }
  }

  static Future<void> _initAwesomeNotifications() async {
    await _awesome.initialize(null, [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        importance: NotificationImportance.High,
        defaultColor: const Color(0xffBF956B),
        onlyAlertOnce: true,
        channelShowBadge: true,
        channelDescription: 'Basic Instant Notification',
      ),
    ]);
  }

  static Future<void> _ensurePermission() async {
    final allowed = await _awesome.isNotificationAllowed();
    if (!allowed) {
      await _awesome.requestPermissionToSendNotifications();
    }
  }

  static Future<void> _startAwesomeListeners() async {
    await _awesome.setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  static void _registerListeners() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      log('Background notification tapped: ${message.data}');
      await _handleNotificationTap(message, NotificationLifeCycle.Background);
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = message.data.map((k, v) => MapEntry(k.toString(), v.toString()));
    // Store lifecycle marker to indicate this notification was created in foreground
    payload[_lifecycleMarkerKey] = NotificationLifeCycle.Foreground.name;

    await _awesome.createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: message.notification?.title ?? message.data['title'] ?? '',
        body: message.notification?.body ?? message.data['body'] ?? '',
        payload: payload,
      ),
    );
  }

  static Future<void> _checkTerminatedNotification() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      log('App opened from terminated notification: ${initialMessage.data}');
      await _handleNotificationTap(initialMessage, NotificationLifeCycle.Terminated);
    }
  }

  static Future<void> _checkInitialAwesomeAction() async {
    final initialAction = await _awesome.getInitialNotificationAction(removeFromActionEvents: true);

    if (initialAction?.payload == null || initialAction!.payload!.isEmpty) {
      return;
    }

    log('App opened from awesome notification action: ${initialAction.payload}');
    await handleAwesomeAction(initialAction);
  }

  @pragma('vm:entry-point')
  static Future<void> handleAwesomeAction(ReceivedAction action) async {
    final payload = action.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    final message = RemoteMessage(data: payload);
    final lifeCycle = _detectNotificationLifeCycle(action, payload);
    log('Detected notification lifecycle: ${lifeCycle.name} for action: ${action.id}');
    await _handleNotificationTap(message, lifeCycle);
  }

  static NotificationLifeCycle _detectNotificationLifeCycle(ReceivedAction action, Map<String, String?> payload) {
    // First, check if Awesome Notifications provided a lifecycle
    if (action.actionLifeCycle != null) {
      log('Using Awesome Notifications lifecycle: ${action.actionLifeCycle!.name}');
      return action.actionLifeCycle!;
    }

    // Second, check if we stored a lifecycle marker in the payload
    final storedLifecycle = payload[_lifecycleMarkerKey];
    if (storedLifecycle != null) {
      try {
        final lifecycle = NotificationLifeCycle.values.firstWhere((lc) => lc.name == storedLifecycle);
        log('Using stored lifecycle marker: ${lifecycle.name}');
        return lifecycle;
      } catch (_) {
        log('Invalid stored lifecycle marker: $storedLifecycle');
      }
    }

    // Third, try to detect current app state
    try {
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (lifecycleState != null) {
        // App is running - determine if foreground or background
        if (lifecycleState == AppLifecycleState.resumed) {
          log('Detected app in foreground (resumed)');
          return NotificationLifeCycle.Foreground;
        } else if (lifecycleState == AppLifecycleState.paused || lifecycleState == AppLifecycleState.inactive) {
          log('Detected app in background (paused/inactive)');
          return NotificationLifeCycle.Background;
        }
      }
    } catch (e) {
      log('Failed to detect app lifecycle state: $e');
    }

    // Default to Terminated if we can't determine the state
    // This typically happens when the app was completely closed
    log('Could not determine lifecycle, defaulting to Terminated');
    return NotificationLifeCycle.Terminated;
  }

  static Future<void> _handleNotificationTap(RemoteMessage message, NotificationLifeCycle lifeCycle) async {
    final resolvedRoute = _resolveRouteFromMessage(message);
    final fingerprint = _buildTapFingerprint(message: message, lifeCycle: lifeCycle, resolvedRoute: resolvedRoute);

    if (_isDuplicateTap(fingerprint)) {
      log('Duplicate notification tap ignored for ${lifeCycle.name}.');
      return;
    }
    _rememberTap(fingerprint);

    _navigateToResolvedRoute(resolvedRoute);
    await _invokeTapCallback(lifeCycle, message);
  }

  static _ResolvedRoute? _resolveRouteFromMessage(RemoteMessage message) {
    final rawArgs = message.data['args'];
    if (rawArgs is! String || rawArgs.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(rawArgs);
      if (decoded is! Map) {
        log('Notification args payload is not a map: $decoded');
        return null;
      }

      final argsMap = Map<String, dynamic>.from(decoded.map((key, value) => MapEntry(key.toString(), value)));
      final routeValue = argsMap.remove('route');
      if (routeValue is! String || routeValue.isEmpty) {
        log('Notification args payload does not contain a valid route: $argsMap');
        return null;
      }

      final navArgs = _buildArgumentsForRoute(routeValue, argsMap);
      return _ResolvedRoute(route: routeValue, arguments: navArgs);
    } catch (error, stackTrace) {
      log('Failed to parse notification args payload: $error', stackTrace: stackTrace);
      return null;
    }
  }

  static Object? _buildArgumentsForRoute(String route, Map<String, dynamic> argsMap) {
    if (_routeArgumentsBuilder != null) {
      try {
        return _routeArgumentsBuilder!.call(route, Map<String, dynamic>.from(argsMap));
      } catch (error, stackTrace) {
        log('routeArgumentsBuilder failed for route $route: $error', stackTrace: stackTrace);
      }
    }

    if (argsMap.containsKey('arguments')) {
      return argsMap['arguments'];
    }

    return argsMap.isEmpty ? null : argsMap;
  }

  static void _navigateToResolvedRoute(_ResolvedRoute? resolvedRoute) {
    if (resolvedRoute == null) {
      return;
    }

    final context = _navigatorKey?.currentContext;
    if (context == null) {
      log('Navigator context is not available. Skipping navigation to ${resolvedRoute.route}.');
      return;
    }

    try {
      context.pushRoute(resolvedRoute.route, arguments: resolvedRoute.arguments);
    } catch (error, stackTrace) {
      log('Failed to navigate to ${resolvedRoute.route}: $error', stackTrace: stackTrace);
    }
  }

  static Future<void> _invokeTapCallback(NotificationLifeCycle lifeCycle, RemoteMessage message) async {
    final callback = switch (lifeCycle) {
      NotificationLifeCycle.Foreground => _onForegroundTap,
      NotificationLifeCycle.Background => _onBackgroundTap,
      NotificationLifeCycle.Terminated => _onTerminatedTap,
    };

    log('Invoking tap callback for ${lifeCycle.name}. Callback ${callback == null ? "is null" : "exists"}.');

    if (callback == null) {
      log('No callback registered for ${lifeCycle.name} lifecycle');
      return;
    }

    try {
      log('Calling ${lifeCycle.name} tap callback with message data: ${message.data}');
      await Future.sync(() => callback.call(message));
      log('Successfully invoked ${lifeCycle.name} tap callback');
    } catch (error, stackTrace) {
      log('Notification tap callback failed for ${lifeCycle.name}: $error', stackTrace: stackTrace);
    }
  }

  static String _buildTapFingerprint({
    required RemoteMessage message,
    required NotificationLifeCycle lifeCycle,
    required _ResolvedRoute? resolvedRoute,
  }) {
    String dataSnapshot;
    try {
      dataSnapshot = json.encode(message.data);
    } catch (_) {
      dataSnapshot = message.data.toString();
    }

    return '${lifeCycle.name}|${resolvedRoute?.route ?? ''}|$dataSnapshot';
  }

  static bool _isDuplicateTap(String fingerprint) {
    final lastTapAt = _lastTapAt;
    if (_lastTapFingerprint != fingerprint || lastTapAt == null) {
      return false;
    }

    return DateTime.now().difference(lastTapAt) <= _tapDedupDuration;
  }

  static void _rememberTap(String fingerprint) {
    _lastTapFingerprint = fingerprint;
    _lastTapAt = DateTime.now();
  }
}
