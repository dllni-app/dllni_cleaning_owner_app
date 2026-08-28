import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/app_semantic_colors.dart';
import '../../features/orders/domain/usecases/cancel_order_use_case.dart';
import '../../features/orders/view/manager/bloc/orders_bloc.dart';
import 'app_button.dart';

class CancelOrderDialog extends StatelessWidget {
  const CancelOrderDialog({
    super.key,
    required this.bloc,
    required this.orderId,
    required this.orderNum,
    this.index = 0,
  });

  final OrdersBloc bloc;
  final int orderId;
  final String orderNum;
  final int index;

  static Future<void> show(
    BuildContext context, {
    required OrdersBloc bloc,
    required int orderId,
    required String orderNum,
    int index = 0,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelOrderDialog(
        bloc: bloc,
        orderId: orderId,
        orderNum: orderNum,
        index: index,
      ),
    );
  }

  void _submitCancel(BuildContext context) {
    bloc.add(
      CancelOrderEvent(
        params: CancelOrderParams(id: orderId),
        index: index,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: context.semanticColors.danger,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppText.titleLarge(
              'تحذير',
              textAlign: TextAlign.center,
              color: context.semanticColors.danger,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 10),
            AppText.bodyMedium(
              'في حال قمت بإلغاء الطلب #$orderNum هذا سيترتب عليه ما يلي:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const _WarningLine('1- خصم من نقاطك الثقة'),
            const _WarningLine('2- زيادة معدل الإلغاء'),
            const _WarningLine('3- نقصان معدل القبول'),
            const _WarningLine('4- تأثير سلبي على ظهورك في الطلبات القادمة'),
            const _WarningLine('5- تنبيه إداري'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'تراجع',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: AppButtonVariant.outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'إلغاء الطلب',
                    onPressed: () => _submitCancel(context),
                    variant: AppButtonVariant.destructive,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AppText.bodySmall(
        text,
        textAlign: TextAlign.start,
        color: const Color(0xff374151),
      ),
    );
  }
}
