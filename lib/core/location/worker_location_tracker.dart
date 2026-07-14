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

  bool get isTracking => _activeBookingId != null;
  int? get activeBookingId => _activeBookingId;

  Future<void> start(int bookingId) async {
    if (bookingId <= 0) return;

    if (Platform.isAndroid) {
      _activeBookingId = bookingId;
      await BackgroundKeepAlive.instance.startForBooking(bookingId);
      return;
    }

    final allowed = await _ensurePermission();
    if (!allowed) {
      _activeBookingId = null;
      return;
    }
    _activeBookingId = bookingId;
    await _startIosStream(bookingId);
  }

  Future<void> stop() async {
    _activeBookingId = null;
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

    // Request "Always" for background updates when possible.
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    return true;
  }

  Future<void> _startIosStream(int bookingId) async {
    if (!Platform.isIOS) return;

    if (_iosPositionSub != null && _activeBookingId == bookingId) return;
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
          (position) => _handlePosition(position, bookingId),
          onError: (_) {},
          cancelOnError: false,
        );
  }

  void _handlePosition(Position position, int bookingId) {
    if (_activeBookingId != bookingId) return;
    final now = DateTime.now();
    if (_lastSentAt != null &&
        now.difference(_lastSentAt!) < _minSendInterval) {
      return;
    }
    _lastSentAt = now;
    unawaited(
      LocationReporter.postLocation(
        bookingId: bookingId,
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}
