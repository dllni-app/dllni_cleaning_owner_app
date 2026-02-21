import 'package:common_package/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AppToast {
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
