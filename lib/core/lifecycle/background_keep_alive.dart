import 'dart:io';

import 'package:common_package/common_package.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../location/location_reporter.dart';

class BackgroundKeepAlive {
  BackgroundKeepAlive._();

  static final BackgroundKeepAlive instance = BackgroundKeepAlive._();

  static const int _serviceId = 6201;
  static const String activeBookingIdKey = 'active_booking_id';
  static bool _initialized = false;

  Future<void> initialize() async {
    if (!Platform.isAndroid || _initialized) return;

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        // New channel id so quieter settings apply on existing installs
        // (Android locks channel importance/sound after first creation).
        channelId: 'owner_background_updates_quiet',
        channelName: 'تحديث الموقع',
        channelDescription: 'إشعار هادئ أثناء مشاركة الموقع مع العميل.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: false,
        showBadge: false,
        onlyAlertOnce: true,
        visibility: NotificationVisibility.VISIBILITY_PRIVATE,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(4000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  Future<void> startForBooking(int bookingId) async {
    if (!Platform.isAndroid || bookingId <= 0) return;
    await initialize();
    if (!_hasToken()) {
      await stop();
      return;
    }

    await FlutterForegroundTask.saveData(
      key: activeBookingIdKey,
      value: bookingId,
    );

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) {
      final updateResult = await FlutterForegroundTask.updateService(
        notificationTitle: 'تتبع الرحلة نشط',
        notificationText: 'مشاركة الموقع أثناء التوجه للعميل',
      );
      if (updateResult case ServiceRequestFailure(:final error)) {
        appLog(
          'BackgroundKeepAlive.updateService failed',
          error: error,
          name: 'BackgroundKeepAlive',
        );
      }
      return;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'تتبع الرحلة نشط',
      notificationText: 'مشاركة الموقع أثناء التوجه للعميل',
      serviceTypes: const <ForegroundServiceTypes>[
        ForegroundServiceTypes.location,
        ForegroundServiceTypes.dataSync,
      ],
      callback: _backgroundKeepAliveCallback,
    );
    if (result case ServiceRequestFailure(:final error)) {
      appLog(
        'BackgroundKeepAlive.start failed',
        error: error,
        name: 'BackgroundKeepAlive',
      );
    }
  }

  Future<void> startIfAuthenticated() async {
    if (!Platform.isAndroid) return;
    await initialize();
    if (!_hasToken()) {
      await stop();
      return;
    }

    final bookingId = await FlutterForegroundTask.getData<int>(
      key: activeBookingIdKey,
    );
    if (bookingId == null || bookingId <= 0) {
      return;
    }
    await startForBooking(bookingId);
  }

  Future<void> stop() async {
    if (!Platform.isAndroid || !_initialized) return;
    await FlutterForegroundTask.removeData(key: activeBookingIdKey);
    if (!await FlutterForegroundTask.isRunningService) return;

    final result = await FlutterForegroundTask.stopService();
    if (result case ServiceRequestFailure(:final error)) {
      appLog(
        'BackgroundKeepAlive.stop failed',
        error: error,
        name: 'BackgroundKeepAlive',
      );
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
  void onRepeatEvent(DateTime timestamp) {
    _tryReportLocation();
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _tryReportLocation();
  }

  Future<void> _tryReportLocation() async {
    try {
      final bookingId = await _readActiveBookingId();
      if (bookingId == null) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await LocationReporter.postLocation(
        bookingId: bookingId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {}
  }

  Future<int?> _readActiveBookingId() async {
    final direct = await FlutterForegroundTask.getData<int>(
      key: BackgroundKeepAlive.activeBookingIdKey,
    );
    if (direct != null && direct > 0) return direct;

    final asString = await FlutterForegroundTask.getData<String>(
      key: BackgroundKeepAlive.activeBookingIdKey,
    );
    if (asString == null) return null;
    final parsed = int.tryParse(asString.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}
