import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

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
            bookingBasePrice: order.financialBookingBaseService,
            bookingServicePriceIncludingAdmin:
                order.financialBookingServicePriceIncludingAdmin,
            bookingAdminMargin: order.financialBookingAdminMargin,
            travelFee:
                order.financialTravelFee ??
                order.myAssignment?.travelFee ??
                order.travelFee,
            addonsTotal: order.addonsTotal,
            totalPrice: order.workerGrossTotal,
            showAddonsTotal: false,
            useWorkerShare: true,
            serviceShareAmount:
                order.financialServiceShare ??
                order.myAssignment?.serviceShareAmount,
            baseServiceShareAmount: order.financialBaseServiceShare,
            serviceAndOperationalShareAmount:
                order.financialServiceAndOperationalShare,
            specialServicesShareAmount: order.financialSpecialServicesShare,
            materialsShareAmount: order.financialMaterialsShare,
            adminMarginPercentage: order.financialAdminMarginPercentage,
            plannedWorkerCount:
                order.financialPlannedWorkerCount ?? order.numberOfWorkers,
            actualWorkerCount: order.financialActualWorkerCount,
            isFinal:
                (order.numberOfWorkers ?? 1) <= 1 ||
                order.isWorkerDistributionFinal,
            hideGroupMaterialPrices: order.hidesGroupMaterialPrices,
            workerAmount: order.workerPayableAmount,
            adminMargin:
                order.financialAdminMargin ??
                order.myAssignment?.adminMarginAmount ??
                order.adminMargin,
          ),
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
