import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/widgets/provisional_pricing_notice.dart';
import '../../../../data/models/fetch_orders_usecase_model.dart';
import '../../worker_payment_summary.dart';

class MissionPaymentSummaryCard extends StatelessWidget {
  const MissionPaymentSummaryCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('ملخص الدفع', fontWeight: FontWeight.w700),
          const SizedBox(height: 10),
          WorkerPaymentSummary(
            basePrice: order.basePrice,
            travelFee: order.myAssignment?.travelFee ?? order.travelFee,
            addonsTotal: order.addonsTotal,
            totalPrice: order.totalPrice,
            showAddonsTotal: false,
            useWorkerShare: order.myAssignment != null,
            serviceShareAmount: order.myAssignment?.serviceShareAmount,
            workerAmount: order.myAssignment?.workerAmount,
            adminMargin: order.adminMargin,
          ),
          if (order.isPricingFinal == false) ...[
            const SizedBox(height: 10),
            const ProvisionalPricingNotice(),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: Color(0xff22C55E),
                size: 18,
              ),
              const SizedBox(width: 6),
              AppText.bodySmall('نقدا عند الاستلام'),
            ],
          ),
        ],
      ),
    );
  }
}
