import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../features/orders/domain/usecases/cancel_order_use_case.dart';
import '../../features/orders/view/manager/bloc/orders_bloc.dart';

class CancelOrderDialog extends StatelessWidget {
  const CancelOrderDialog({
    super.key,
    required this.bloc,
    required this.orderId,
    required this.orderNum,
  });

  final OrdersBloc bloc;
  final int orderId;
  final String orderNum;

  static Future<void> show(
    BuildContext context, {
    required OrdersBloc bloc,
    required int orderId,
    required String orderNum,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          CancelOrderDialog(bloc: bloc, orderId: orderId, orderNum: orderNum),
    );
  }

  void _submitCancel(BuildContext context) {
    bloc.add(
      CancelOrderEvent(params: CancelOrderParams(id: orderId), index: 0),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xffE11D48),
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppText.titleLarge(
              'تحذير',
              textAlign: TextAlign.center,
              color: const Color(0xffE11D48),
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
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff7C879D),
                      foregroundColor: Colors.white,
                    ),
                    child: AppText.labelLarge('تراجع', color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _submitCancel(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffE11D48),
                      foregroundColor: Colors.white,
                    ),
                    child: AppText.labelLarge(
                      'إلغاء الطلب',
                      color: Colors.white,
                    ),
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
