import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_layout.dart';

class CalenderAppBar extends StatelessWidget {
  const CalenderAppBar({super.key});

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
      padding: AppSpace.pagePadding(
        context,
      ).add(const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm)),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleLarge('تقويمي', fontWeight: FontWeight.w700),
            const SizedBox(height: AppSpace.xxs),
            AppText.bodySmall(
              'اختر يومًا لعرض المهام المجدولة',
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
