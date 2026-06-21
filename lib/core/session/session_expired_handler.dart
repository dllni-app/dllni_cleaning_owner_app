import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:flutter/material.dart';

class SessionExpiredHandler {
  SessionExpiredHandler._();

  static GlobalKey<NavigatorState>? navigatorKey;
  static bool _isHandling = false; // تغيير الاسم ليكون أكثر دقة

  static Future<void> handle() async {
    // 1. حماية إضافية: إذا كان هناك معالجة جارية، لا تفعل شيئاً
    if (_isHandling) return;

    _isHandling = true;
    try {
      // 2. استخدام الخدمة المركزية لتنظيف الاشتراكات (وهذا صحيح)
      final pusherService = getIt<CleaningBookingPusherService>();
      await pusherService.disposeAllForSession();

      // 3. مسح البيانات المحلية
      await SharedPreferencesHelper.clearData();

      // 4. التأكد من وجود الـ navigatorKey قبل استخدامه
      final context = navigatorKey?.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
      }
    } catch (e) {
      // يفضل إضافة طباعة بسيطة لمعرفة سبب فشل التنظيف إن وجد
      debugPrint('Error during session expiration: $e');
    } finally {
      _isHandling = false;
    }
  }
}
