import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

const String supportWhatsAppUrl = 'https://wa.me/message/XJOZBNT3VS5SJ1';

Future<void> launchSupportWhatsApp(BuildContext context) async {
  final uri = Uri.parse(supportWhatsAppUrl);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppToast.showToast(
      context: context,
      message: 'تعذر فتح واتساب',
      type: ToastificationType.error,
    );
  }
}
