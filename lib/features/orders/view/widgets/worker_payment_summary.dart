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
    final serviceAmount = useWorkerShare ? serviceShareAmount : basePrice;
    final netProfit = workerAmount ??
        ((totalPrice ?? 0) - (adminMargin ?? 0));

    return Column(
      children: [
        _PaymentRow(
          label: 'قيمة الخدمة',
          amount: serviceAmount.formatMoney(),
        ),
        12.verticalSpace,
        _PaymentRow(
          label: 'رسوم التنقل',
          amount: travelFee.formatMoney(),
        ),
        12.verticalSpace,
        _PaymentRow(
          label: 'هامش الإدارة',
          amount: adminMargin.formatMoney(),
        ),
        12.verticalSpace,
        _PaymentRow(
          label: 'الإجمالي',
          amount: totalPrice.formatMoney(),
        ),
        18.verticalSpace,
        LayoutBuilder(
          builder: (context, constraints) {
            final dashWidth = 6.0.w;
            final dashSpace = 6.0.w;
            final dashCount =
                (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
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
          label: 'صافي الربح',
          amount: netProfit.formatMoney(),
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
