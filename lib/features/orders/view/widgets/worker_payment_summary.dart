import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class WorkerPaymentSummary extends StatelessWidget {
  const WorkerPaymentSummary({
    super.key,
    required this.basePrice,
    required this.travelFee,
    required this.adminMargin,
    required this.addonsTotal,
    required this.totalPrice,
    this.showAddonsTotal = true,
    this.serviceShareAmount,
    this.workerAmount,
    this.useWorkerShare = false,
  });

  final num? basePrice;
  final num? travelFee;
  final num? adminMargin;
  final num? addonsTotal;
  final num? totalPrice;
  final bool showAddonsTotal;
  final num? serviceShareAmount;
  final num? workerAmount;
  final bool useWorkerShare;

  @override
  Widget build(BuildContext context) {
    if (useWorkerShare && serviceShareAmount == null && travelFee == null) {
      // Accepted/pre-acceptance offers may expose only a worker-specific
      // payable amount. Do not fill the absent component breakdown with zeros.
      return _PaymentRow(
        label: 'مستحق العامل',
        amount: workerAmount?.formatMoney() ?? 'قيد التحديد',
        isTotal: true,
        labelColor: context.primaryContainer,
        amountColor: context.primaryContainer,
      );
    }
    // In worker-share mode the booking base price belongs to the whole order,
    // not to the current worker. Never fall back to it while assignment pricing
    // is still being refreshed, otherwise a multi-worker order briefly shows
    // the entire service amount as this worker's earnings.
    final serviceAmount = useWorkerShare
        ? (serviceShareAmount ?? 0)
        : ((basePrice ?? 0) + (addonsTotal ?? 0));
    final calculatedGrossTotal = serviceAmount + (travelFee ?? 0);
    final grossTotal = useWorkerShare
        ? calculatedGrossTotal
        : (calculatedGrossTotal > 0 ? calculatedGrossTotal : (totalPrice ?? 0));
    // Administration margin is a customer-side charge above the worker share,
    // not a deduction from this worker's payout.
    final calculatedNetProfit = grossTotal;
    final hasCalculableNet = useWorkerShare
        ? serviceShareAmount != null || travelFee != null || adminMargin != null
        : calculatedGrossTotal > 0 || totalPrice != null || adminMargin != null;
    final netProfit =
        workerAmount ??
        (hasCalculableNet
            ? (calculatedNetProfit > 0 ? calculatedNetProfit : 0)
            : null);

    return Column(
      children: [
        _PaymentRow(
          label: 'قيمة الخدمة',
          amount: useWorkerShare && serviceShareAmount == null
              ? 'قيد التحديد'
              : serviceAmount.formatMoney(),
        ),
        12.verticalSpace,
        _PaymentRow(
          label: 'رسوم التنقل',
          amount: travelFee?.formatMoney() ?? 'قيد التحديد',
        ),
        if (!useWorkerShare) ...[
          12.verticalSpace,
          _PaymentRow(label: 'الإجمالي', amount: grossTotal.formatMoney()),
          12.verticalSpace,
          _PaymentRow(label: 'هامش الإدارة', amount: adminMargin.formatMoney()),
        ],
        18.verticalSpace,
        LayoutBuilder(
          builder: (context, constraints) {
            final dashWidth = 6.0.w;
            final dashSpace = 6.0.w;
            final dashCount =
                (constraints.constrainWidth() / (dashWidth + dashSpace))
                    .floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(dashCount, (_) {
                return Container(
                  width: dashWidth,
                  height: 2.h,
                  color: context.primaryContainer,
                );
              }),
            );
          },
        ),
        18.verticalSpace,
        _PaymentRow(
          label: 'مستحق العامل',
          amount: netProfit?.formatMoney() ?? 'قيد التحديد',
          isTotal: true,
          labelColor: context.primaryContainer,
          amountColor: context.primaryContainer,
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.amount,
    this.labelColor,
    this.amountColor,
    this.isTotal = false,
  });

  final String label;
  final String amount;
  final Color? labelColor;
  final Color? amountColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: AppText.labelMedium(
              label,
              fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
              color: labelColor,
            ),
          ),
        ),
        AppText.labelMedium(
          amount,
          fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          color: amountColor,
        ),
      ],
    );
  }
}
