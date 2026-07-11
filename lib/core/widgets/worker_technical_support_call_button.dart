import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

const String defaultSupportPhoneNumber = '+963000000000';

Future<void> launchSupportCall(
  BuildContext context, {
  String supportPhoneNumber = defaultSupportPhoneNumber,
}) async {
  final uri = Uri(scheme: 'tel', path: supportPhoneNumber);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppToast.showToast(
      context: context,
      message: 'تعذر فتح تطبيق الاتصال',
      type: ToastificationType.error,
    );
  }
}
