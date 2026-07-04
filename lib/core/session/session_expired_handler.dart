import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SessionExpiredHandler {
  SessionExpiredHandler._();

  static GlobalKey<NavigatorState>? navigatorKey;
  static bool _isHandling = false;

  static Future<void> handle() async {
    if (_isHandling) return;

    final token = (SharedPreferencesHelper.getData(key: 'token') ?? '')
        .toString()
        .trim();
    if (token.isEmpty) return;

    _isHandling = true;
    AppToast.setSuppressErrorToasts(true);
    try {
      final pusherService = getIt<CleaningBookingPusherService>();
      await pusherService.disposeAllForSession();

      await SharedPreferencesHelper.clearData();

      final context = navigatorKey?.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
      AppToast.showWarningGlobal('errorMessage.unauthorized'.tr());
    } catch (e) {
      debugPrint('Error during session expiration: $e');
    } finally {
      _isHandling = false;
      Future.delayed(
        const Duration(milliseconds: 1500),
        () => AppToast.setSuppressErrorToasts(false),
      );
    }
  }
}
