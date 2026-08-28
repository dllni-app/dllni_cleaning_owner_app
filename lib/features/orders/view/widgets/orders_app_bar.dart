import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_layout.dart';

class OrdersAppBar extends StatelessWidget {
  const OrdersAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      width: context.width,
      constraints: const BoxConstraints(minHeight: 72),
      padding: AppSpace.pagePadding(
        context,
      ).add(const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm)),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleLarge('الطلبات', fontWeight: FontWeight.w700),
            const SizedBox(height: AppSpace.xxs),
            AppText.bodySmall(
              'تابع حالة كل مهمة والإجراء التالي المطلوب',
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
