import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/widgets/provisional_pricing_notice.dart';
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

  bool get _usesWorkerShare => order.myAssignment != null;

  String get _currency =>
      order.myAssignment?.currency?.trim().isNotEmpty == true
      ? order.myAssignment!.currency!.trim()
      : 'SYP';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium(
            _usesWorkerShare ? 'أرباحك من الطلب' : 'تفاصيل الدفع',
            fontWeight: FontWeight.w400,
          ),
          12.verticalSpace,
          Divider(color: Colors.black.withAlpha(42)),
          12.verticalSpace,
          WorkerPaymentSummary(
            basePrice: order.basePrice,
            travelFee: order.myAssignment?.travelFee ?? order.travelFee,
            addonsTotal: order.addonsTotal,
            totalPrice: order.totalPrice,
            currency: _currency,
            showAddonsTotal: showAddonsTotal,
            useWorkerShare: _usesWorkerShare,
            serviceShareAmount: order.myAssignment?.serviceShareAmount,
            workerAmount: order.myAssignment?.workerAmount,
            adminMargin: order.adminMargin,
          ),
          if (order.isPricingFinal == false) ...[
            12.verticalSpace,
            const ProvisionalPricingNotice(),
          ],
        ],
      ),
    );
  }
}
