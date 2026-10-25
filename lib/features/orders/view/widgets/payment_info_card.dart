import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/theme/worker_app_colors.dart';

import '../../data/models/fetch_orders_usecase_model.dart';
import 'worker_payment_summary.dart';

class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard({
    super.key,
    required this.order,
    this.showAddonsTotal = false,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final bool showAddonsTotal;

  bool get _usesWorkerShare => true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: WorkerAppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WorkerAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium(
            'مستحقاتك من هذا الطلب',
            fontWeight: FontWeight.w400,
          ),
          12.verticalSpace,
          Divider(color: Colors.black.withAlpha(42)),
          12.verticalSpace,
          if (order.workerPayableAmount == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('مستحق العامل قيد التحديد. سيتم تحديثه من الخادم.'),
            )
          else
            WorkerPaymentSummary(
              basePrice: order.basePrice,
              travelFee: order.myAssignment?.travelFee ?? order.travelFee,
              addonsTotal: order.addonsTotal,
              totalPrice: order.workerGrossTotal,

              showAddonsTotal: showAddonsTotal,
              useWorkerShare: _usesWorkerShare,
              serviceShareAmount: order.myAssignment?.serviceShareAmount,
              workerAmount: order.workerPayableAmount,
              adminMargin:
                  order.myAssignment?.adminMarginAmount ?? order.adminMargin,
            ),
        ],
      ),
    );
  }
}
