import 'package:common_package/extensions/theme_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AppToast {
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Call once at app startup with the same [GlobalKey] passed to [MaterialApp.navigatorKey].
  static void bindNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static const String defaultSuccessMessage = 'تمت العملية بنجاح';
  static const String defaultErrorMessage = 'حدث خطأ';

  static String _nonEmptyOr(String? message, String fallback) {
    final t = message?.trim();
    if (t == null || t.isEmpty) return fallback;
    return t;
  }

  /// Shows an error toast using the root navigator context (no [BuildContext] required).
  static void showErrorGlobal([String? message]) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      if (kDebugMode) {
        debugPrint('AppToast.showErrorGlobal: no navigator context');
      }
      return;
    }
    showToast(
      context: context,
      message: _nonEmptyOr(message, defaultErrorMessage),
      type: ToastificationType.error,
    );
  }

  /// Shows a success toast using the root navigator context (no [BuildContext] required).
  static void showSuccessGlobal([String? message]) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      if (kDebugMode) {
        debugPrint('AppToast.showSuccessGlobal: no navigator context');
      }
      return;
    }
    showToast(
      context: context,
      message: _nonEmptyOr(message, defaultSuccessMessage),
      type: ToastificationType.success,
    );
  }

  static void showToast({
    required BuildContext context,
    required String message,
    required ToastificationType type,
    Alignment alignment = Alignment.topCenter,
    Duration duration = const Duration(seconds: 3),
  }) {
    switch (type) {
      case ToastificationType.success:
        toastification.show(
          context: context,
          title: Text(message, style: TextStyle(color: context.onPrimary)),
          type: ToastificationType.success,
          alignment: alignment,
          autoCloseDuration: duration,
          backgroundColor: context.primary,
          icon: Icon(Icons.check_circle_outline, color: context.onPrimary),
        );
        break;
      case ToastificationType.error:
        toastification.show(
          context: context,
          title: Text(message, style: TextStyle(color: context.onError)),
          type: ToastificationType.error,
          alignment: alignment,
          autoCloseDuration: duration,
          backgroundColor: context.error,
          icon: Icon(Icons.error, color: context.onError),
        );
        break;
      case ToastificationType.warning:
        toastification.show(
          context: context,
          title: Text(message, style: TextStyle(color: context.onPrimary)),
          type: ToastificationType.warning,
          alignment: alignment,
          autoCloseDuration: duration,
          backgroundColor: context.primary,
          icon: Icon(Icons.error_outline, color: context.onPrimary),
        );
        break;
      case ToastificationType.info:
        toastification.show(
          context: context,
          title: Text(message, style: TextStyle(color: context.onPrimary)),
          type: ToastificationType.info,
          alignment: alignment,
          autoCloseDuration: duration,
          backgroundColor: context.primary,
          icon: Icon(Icons.info_outline, color: context.onPrimary),
        );
        break;
    }
  }
}
