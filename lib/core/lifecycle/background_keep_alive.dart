import 'dart:io';

import 'package:common_package/common_package.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundKeepAlive {
  BackgroundKeepAlive._();

  static final BackgroundKeepAlive instance = BackgroundKeepAlive._();

  static const int _serviceId = 6201;
  static bool _initialized = false;

  Future<void> initialize() async {
    if (!Platform.isAndroid || _initialized) return;

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'owner_background_updates',
        channelName: 'Background Updates',
        channelDescription: 'Keeps order data syncing while app is in background.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  Future<void> startIfAuthenticated() async {
    if (!Platform.isAndroid) return;
    await initialize();
    if (!_hasToken()) {
      await stop();
      return;
    }

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) return;

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'التحديث بالخلفية مفعّل',
      notificationText: 'جاري تحديث الطلبات والموقع أثناء وجود التطبيق بالخلفية',
      serviceTypes: const <ForegroundServiceTypes>[ForegroundServiceTypes.dataSync],
      callback: _backgroundKeepAliveCallback,
    );
    if (result case ServiceRequestFailure(:final error)) {
      appLog('BackgroundKeepAlive.start failed', error: error, name: 'BackgroundKeepAlive');
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid || !_initialized) return;
    if (!await FlutterForegroundTask.isRunningService) return;

    final result = await FlutterForegroundTask.stopService();
    if (result case ServiceRequestFailure(:final error)) {
      appLog('BackgroundKeepAlive.stop failed', error: error, name: 'BackgroundKeepAlive');
    }
  }

  bool _hasToken() {
    final token = (SharedPreferencesHelper.getData(key: 'token') ?? '')
        .toString()
        .trim();
    return token.isNotEmpty;
  }
}

@pragma('vm:entry-point')
void _backgroundKeepAliveCallback() {
  FlutterForegroundTask.setTaskHandler(_BackgroundKeepAliveTaskHandler());
}

class _BackgroundKeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}

  @override
  void onNotificationPressed() {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
}
