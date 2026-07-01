import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../helpers/order_details_support_navigation.dart';

class MissionSupportButton extends StatelessWidget {
  const MissionSupportButton({super.key, required this.orderId});

  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: orderId == null
          ? null
          : () => openOrderUrgentSupport(context, orderId!),
      style: FilledButton.styleFrom(
        backgroundColor: context.error,
        foregroundColor: context.onError,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: AppText.labelLarge(
        'طلب دعم عاجل',
        color: context.onError,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
