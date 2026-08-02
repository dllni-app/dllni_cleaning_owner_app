import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';

Future<void> launchLegalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    AppToast.showToast(
      context: context,
      message: 'تعذر فتح الرابط',
      type: ToastificationType.error,
    );
  }
}

Future<void> launchPrivacyPolicy(BuildContext context) {
  return launchLegalUrl(context, AppConfig.privacyPolicyUrl);
}

Future<void> launchTermsAndConditions(BuildContext context) {
  return launchLegalUrl(context, AppConfig.termsAndConditionsUrl);
}
