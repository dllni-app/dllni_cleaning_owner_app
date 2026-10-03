import 'package:flutter/material.dart';

import '../../../../core/theme/worker_app_colors.dart';
import '../../../../core/widgets/worker_screen_header.dart';

class OrdersAppBar extends StatelessWidget {
  const OrdersAppBar({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return WorkerScreenHeader(
      title: 'الطلبات',
      subtitle: 'رتّب يومك حسب الإجراء المطلوب',
      action: onRefresh == null
          ? null
          : Material(
              color: WorkerAppColors.canvas,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(13),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: WorkerAppColors.brandPrimary,
                  ),
                ),
              ),
            ),
    );
  }
}
