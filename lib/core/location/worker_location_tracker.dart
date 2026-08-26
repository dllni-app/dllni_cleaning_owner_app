import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../lifecycle/background_keep_alive.dart';
import 'location_reporter.dart';

class WorkerLocationTracker {
  WorkerLocationTracker._();

  static final WorkerLocationTracker instance = WorkerLocationTracker._();

  static const Duration _minSendInterval = Duration(seconds: 4);

  StreamSubscription<Position>? _iosPositionSub;
  DateTime? _lastSentAt;
  int? _activeBookingId;
  int? _activeSessionId;

  bool get isTracking => _activeBookingId != null;
  int? get activeBookingId => _activeBookingId;
  int? get activeSessionId => _activeSessionId;

  Future<void> start(int bookingId, {int? sessionId}) async {
    if (bookingId <= 0) return;

    if (Platform.isAndroid) {
      _activeBookingId = bookingId;
      _activeSessionId = sessionId;
      await BackgroundKeepAlive.instance.startForBooking(
        bookingId,
        sessionId: sessionId,
      );
      return;
    }

    final allowed = await _ensurePermission();
    if (!allowed) {
      _activeBookingId = null;
      _activeSessionId = null;
      return;
    }
    _activeBookingId = bookingId;
    _activeSessionId = sessionId;
    await _startIosStream(bookingId, sessionId: sessionId);
  }

  Future<void> stop() async {
    _activeBookingId = null;
    _activeSessionId = null;
    _lastSentAt = null;
    await _iosPositionSub?.cancel();
    _iosPositionSub = null;

    if (Platform.isAndroid) {
      await BackgroundKeepAlive.instance.stop();
    }
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    return true;
  }

  Future<void> _startIosStream(int bookingId, {int? sessionId}) async {
    if (!Platform.isIOS) return;

    if (_iosPositionSub != null &&
        _activeBookingId == bookingId &&
        _activeSessionId == sessionId) {
      return;
    }
    await _iosPositionSub?.cancel();
    _lastSentAt = null;

    final settings = AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      activityType: ActivityType.automotiveNavigation,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
      allowBackgroundLocationUpdates: true,
      distanceFilter: 0,
    );

    _iosPositionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (position) => _handlePosition(
            position,
            bookingId,
            sessionId: sessionId,
          ),
          onError: (_) {},
          cancelOnError: false,
        );
  }

  void _handlePosition(
    Position position,
    int bookingId, {
    int? sessionId,
  }) {
    if (_activeBookingId != bookingId || _activeSessionId != sessionId) return;
    final now = DateTime.now();
    if (_lastSentAt != null &&
        now.difference(_lastSentAt!) < _minSendInterval) {
      return;
    }
    _lastSentAt = now;
    unawaited(
      LocationReporter.postLocation(
        bookingId: bookingId,
        sessionId: sessionId,
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}
