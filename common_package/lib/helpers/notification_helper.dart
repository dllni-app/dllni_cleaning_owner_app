import 'dart:async';
import 'dart:convert';
import 'package:common_package/helpers/app_log.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:common_package/extensions/route_extensions.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

typedef NotificationTapCallback =
    FutureOr<void> Function(RemoteMessage message);
typedef NotificationRouteArgumentsBuilder =
    Object? Function(String route, Map<String, dynamic> argsMap);
typedef FcmTokenAvailableCallback = FutureOr<void> Function(String token);

class _ResolvedRoute {
  final String route;
  final Object? arguments;

  const _ResolvedRoute({required this.route, this.arguments});
}

const String _lifecycleMarkerKey = '_notification_lifecycle';
const String _basicChannelKey = 'basic_channel';

const String _notificationIcon = 'resource://drawable/notification_icon';
const String _notificationLargeIcon = 'resource://mipmap/launcher_icon';

List<NotificationChannel> get _basicNotificationChannels => [
  NotificationChannel(
    channelKey: _basicChannelKey,
    channelName: 'Basic Notifications',
    importance: NotificationImportance.High,
    defaultColor: const Color(0xff1E2A7B),
    onlyAlertOnce: false,
    channelShowBadge: true,
    channelDescription: 'Basic Instant Notification',
  ),
];

// Future<void> _initializeAwesomeNotificationsInIsolate() async {
//   await AwesomeNotifications().initialize(null, _basicNotificationChannels);
// }

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // await _initializeAwesomeNotificationsInIsolate();
  // final payload = message.data.map(
  //   (k, v) => MapEntry(k.toString(), v.toString()),
  // );
  // // Store lifecycle marker to indicate this notification was created in background
  // payload[_lifecycleMarkerKey] = NotificationLifeCycle.Background.name;
  //
  // await AwesomeNotifications().createNotification(
  //   content: NotificationContent(
  //     id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
  //     channelKey: _basicChannelKey,
  //     title:
  //         message.notification?.title ??
  //         message.data['title'] ??
  //         'New Notification',
  //     body: message.notification?.body ?? message.data['body'] ?? '',
  //     payload: payload,
  //   ),
  // );

  appLog(
    'Background message received: '
        '${message.messageId} ${message.data}',
  );
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  appLog('Notification clicked: ${action.payload}');
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
  static FcmTokenAvailableCallback? _onFcmTokenAvailable;

  static String? _lastTapFingerprint;
  static DateTime? _lastTapAt;
  static const Duration _tapDedupDuration = Duration(seconds: 3);
  static const int _maxTokenFetchAttempts = 3;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> initAllNotifications({
    required String tokenKey,
    required GlobalKey<NavigatorState> navigatorKey,
    NotificationTapCallback? onTerminatedTap,
    NotificationTapCallback? onBackgroundTap,
    NotificationTapCallback? onForegroundTap,
    NotificationRouteArgumentsBuilder? routeArgumentsBuilder,
    FcmTokenAvailableCallback? onFcmTokenAvailable,
  }) async {
    _navigatorKey = navigatorKey;
    _onTerminatedTap = onTerminatedTap;
    _onBackgroundTap = onBackgroundTap;
    _onForegroundTap = onForegroundTap;
    _routeArgumentsBuilder = routeArgumentsBuilder;
    _onFcmTokenAvailable = onFcmTokenAvailable;

    await _initFirebase(tokenKey);
    await _initAwesomeNotifications();
    await _ensurePermission();
    _registerListeners();
    await _checkTerminatedNotification();
    await _startAwesomeListeners();
    await _checkInitialAwesomeAction();
  }

  /// Registers the stored FCM token with the backend when the user is authenticated.
  static Future<void> syncStoredToken({required String tokenKey}) async {
    final raw = SharedPreferencesHelper.getData(key: tokenKey);
    if (raw == null) return;
    final token = raw.toString().trim();
    if (token.isEmpty) return;
    await _notifyTokenAvailable(token);
  }

  static Future<void> _initFirebase(String tokenKey) async {
    await Firebase.initializeApp();
    await _requestMessagingPermission();
    _registerTokenRefreshListener(tokenKey);
    unawaited(_fetchAndPersistToken(tokenKey));
  }

  static Future<void> getToken(String tokenKey) async {
    await _fetchAndPersistToken(tokenKey);
  }

  static Future<void> _fetchAndPersistToken(String tokenKey) async {
    final token = await _fetchTokenWithRetry();
    if (token != null && token.isNotEmpty) {
      await _persistToken(tokenKey, token);
      return;
    }

    appLog(
      'FCM token is unavailable right now. App startup will continue and token can be fetched later.',
    );
  }

  static Future<void> _requestMessagingPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      appLog(
        'FCM notification permission status: ${settings.authorizationStatus.name}',
      );
    } catch (error, stackTrace) {
      appLog('Failed to request FCM permission: $error', stackTrace: stackTrace);
    }
  }

  static Future<String?> _fetchTokenWithRetry() async {
    for (var attempt = 1; attempt <= _maxTokenFetchAttempts; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }

        appLog('FCM token attempt $attempt returned empty token.');
      } catch (error, stackTrace) {
        final retryable = _isRetryableTokenFailure(error);
        appLog(
          'FCM token attempt $attempt failed (retryable: $retryable): $error',
          stackTrace: stackTrace,
        );
        if (!retryable) {
          return null;
        }
      }

      if (attempt < _maxTokenFetchAttempts) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    return null;
  }

  static bool _isRetryableTokenFailure(Object error) {
    final text = error.toString().toUpperCase();
    return text.contains('SERVICE_NOT_AVAILABLE') ||
        text.contains('TOO_MANY_REQUESTS') ||
        text.contains('TIMEOUT') ||
        text.contains('UNAVAILABLE');
  }

  static void _registerTokenRefreshListener(String tokenKey) {
    if (_tokenRefreshSubscription != null) {
      return;
    }

    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(
          (token) async {
            if (token.isEmpty) {
              return;
            }
            await _persistToken(tokenKey, token);
          },
          onError: (Object error, StackTrace stackTrace) {
            appLog(
              'FCM token refresh stream failed: $error',
              stackTrace: stackTrace,
            );
          },
        );
  }

  static Future<void> _persistToken(String tokenKey, String token) async {
    await SharedPreferencesHelper.saveData(key: tokenKey, value: token);
    appLog('FCM Token: $token');
    await _notifyTokenAvailable(token);
  }

  static Future<void> _notifyTokenAvailable(String token) async {
    final callback = _onFcmTokenAvailable;
    if (callback == null) return;
    try {
      await Future.sync(() => callback.call(token));
    } catch (error, stackTrace) {
      appLog(
        'FCM token registration callback failed: $error',
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _initAwesomeNotifications() async {
    await _awesome.initialize(_notificationIcon, _basicNotificationChannels);
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
      appLog('Background notification tapped: ${message.data}');
      await _handleNotificationTap(message, NotificationLifeCycle.Background);
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = message.data.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
    // Store lifecycle marker to indicate this notification was created in foreground
    payload[_lifecycleMarkerKey] = NotificationLifeCycle.Foreground.name;

    await _awesome.createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _basicChannelKey,
        title: message.notification?.title ?? message.data['title'] ?? '',
        body: message.notification?.body ?? message.data['body'] ?? '',
        payload: payload,
        icon: _notificationIcon,
        largeIcon: _notificationLargeIcon,
      ),
    );
  }

  static Future<void> _checkTerminatedNotification() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      appLog('App opened from terminated notification: ${initialMessage.data}');
      await _handleNotificationTap(
        initialMessage,
        NotificationLifeCycle.Terminated,
      );
    }
  }

  static Future<void> _checkInitialAwesomeAction() async {
    final initialAction = await _awesome.getInitialNotificationAction(
      removeFromActionEvents: true,
    );

    if (initialAction?.payload == null || initialAction!.payload!.isEmpty) {
      return;
    }

    appLog(
      'App opened from awesome notification action: ${initialAction.payload}',
    );
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
    appLog(
      'Detected notification lifecycle: ${lifeCycle.name} for action: ${action.id}',
    );
    await _handleNotificationTap(message, lifeCycle);
  }

  static NotificationLifeCycle _detectNotificationLifeCycle(
    ReceivedAction action,
    Map<String, String?> payload,
  ) {
    // First, check if Awesome Notifications provided a lifecycle
    if (action.actionLifeCycle != null) {
      appLog(
        'Using Awesome Notifications lifecycle: ${action.actionLifeCycle!.name}',
      );
      return action.actionLifeCycle!;
    }

    // Second, check if we stored a lifecycle marker in the payload
    final storedLifecycle = payload[_lifecycleMarkerKey];
    if (storedLifecycle != null) {
      try {
        final lifecycle = NotificationLifeCycle.values.firstWhere(
          (lc) => lc.name == storedLifecycle,
        );
        appLog('Using stored lifecycle marker: ${lifecycle.name}');
        return lifecycle;
      } catch (_) {
        appLog('Invalid stored lifecycle marker: $storedLifecycle');
      }
    }

    // Third, try to detect current app state
    try {
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (lifecycleState != null) {
        // App is running - determine if foreground or background
        if (lifecycleState == AppLifecycleState.resumed) {
          appLog('Detected app in foreground (resumed)');
          return NotificationLifeCycle.Foreground;
        } else if (lifecycleState == AppLifecycleState.paused ||
            lifecycleState == AppLifecycleState.inactive) {
          appLog('Detected app in background (paused/inactive)');
          return NotificationLifeCycle.Background;
        }
      }
    } catch (e) {
      appLog('Failed to detect app lifecycle state: $e');
    }

    // Default to Terminated if we can't determine the state
    // This typically happens when the app was completely closed
    appLog('Could not determine lifecycle, defaulting to Terminated');
    return NotificationLifeCycle.Terminated;
  }

  static Future<void> _handleNotificationTap(
    RemoteMessage message,
    NotificationLifeCycle lifeCycle,
  ) async {
    final resolvedRoute = _resolveRouteFromMessage(message);
    final fingerprint = _buildTapFingerprint(
      message: message,
      lifeCycle: lifeCycle,
      resolvedRoute: resolvedRoute,
    );

    if (_isDuplicateTap(fingerprint)) {
      appLog('Duplicate notification tap ignored for ${lifeCycle.name}.');
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
        appLog('Notification args payload is not a map: $decoded');
        return null;
      }

      final argsMap = Map<String, dynamic>.from(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      final routeValue = argsMap.remove('route');
      if (routeValue is! String || routeValue.isEmpty) {
        appLog(
          'Notification args payload does not contain a valid route: $argsMap',
        );
        return null;
      }

      final navArgs = _buildArgumentsForRoute(routeValue, argsMap);
      return _ResolvedRoute(route: routeValue, arguments: navArgs);
    } catch (error, stackTrace) {
      appLog(
        'Failed to parse notification args payload: $error',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Object? _buildArgumentsForRoute(
    String route,
    Map<String, dynamic> argsMap,
  ) {
    if (_routeArgumentsBuilder != null) {
      try {
        return _routeArgumentsBuilder!.call(
          route,
          Map<String, dynamic>.from(argsMap),
        );
      } catch (error, stackTrace) {
        appLog(
          'routeArgumentsBuilder failed for route $route: $error',
          stackTrace: stackTrace,
        );
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
      appLog(
        'Navigator context is not available. Skipping navigation to ${resolvedRoute.route}.',
      );
      return;
    }

    try {
      context.pushRoute(
        resolvedRoute.route,
        arguments: resolvedRoute.arguments,
      );
    } catch (error, stackTrace) {
      appLog(
        'Failed to navigate to ${resolvedRoute.route}: $error',
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _invokeTapCallback(
    NotificationLifeCycle lifeCycle,
    RemoteMessage message,
  ) async {
    final callback = switch (lifeCycle) {
      NotificationLifeCycle.Foreground => _onForegroundTap,
      NotificationLifeCycle.Background => _onBackgroundTap,
      NotificationLifeCycle.Terminated => _onTerminatedTap,
    };

    appLog(
      'Invoking tap callback for ${lifeCycle.name}. Callback ${callback == null ? "is null" : "exists"}.',
    );

    if (callback == null) {
      appLog('No callback registered for ${lifeCycle.name} lifecycle');
      return;
    }

    try {
      appLog(
        'Calling ${lifeCycle.name} tap callback with message data: ${message.data}',
      );
      await Future.sync(() => callback.call(message));
      appLog('Successfully invoked ${lifeCycle.name} tap callback');
    } catch (error, stackTrace) {
      appLog(
        'Notification tap callback failed for ${lifeCycle.name}: $error',
        stackTrace: stackTrace,
      );
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
