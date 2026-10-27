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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: WorkerAppColors.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: WorkerAppColors.brandPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تفاصيل حصتك من الطلب',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: WorkerAppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: WorkerAppColors.border, height: 1),
          const SizedBox(height: 16),
          if (order.workerPayableAmount == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('مستحق العامل قيد التحديد. سيتم تحديثه من الخادم.'),
            )
          else
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

              showAddonsTotal: showAddonsTotal,
              useWorkerShare: _usesWorkerShare,
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
        ],
      ),
    );
  }
}
