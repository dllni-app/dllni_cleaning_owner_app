import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:flutter/material.dart';

class SessionExpiredHandler {
  SessionExpiredHandler._();

  static GlobalKey<NavigatorState>? navigatorKey;

  static bool _navigating = false;

  static int? _resolveWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  static Future<void> handle() async {
    if (_navigating) return;
    _navigating = true;
    try {
      final workerId = _resolveWorkerId();
      if (workerId != null) {
        final pusher = getIt<CleaningBookingPusherService>();
        pusher.setWorkerHandler(workerId, null);
        await pusher.unsubscribeWorkerChannel(workerId);
      }
      await SharedPreferencesHelper.clearData();
      navigatorKey?.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } finally {
      _navigating = false;
    }
  }
}
