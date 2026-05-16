import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:flutter/material.dart';

class SessionExpiredHandler {
  SessionExpiredHandler._();

  static GlobalKey<NavigatorState>? navigatorKey;

  static bool _navigating = false;

  static Future<void> handle() async {
    if (_navigating) return;
    _navigating = true;
    try {
      await getIt<CleaningBookingPusherService>().disposeAllForSession();
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
