import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class WorkerPaymentSummary extends StatelessWidget {
  const WorkerPaymentSummary({
    super.key,
    required this.basePrice,
    required this.travelFee,
    required this.addonsTotal,
    required this.totalPrice,
    required this.currency,
    this.showAddonsTotal = true,
    this.serviceShareAmount,
    this.workerAmount,
    this.useWorkerShare = false,
  });

  final num? basePrice;
  final num? travelFee;
  final num? addonsTotal;
  final num? totalPrice;
  final String currency;
  final bool showAddonsTotal;
  final num? serviceShareAmount;
  final num? workerAmount;
  final bool useWorkerShare;

  String _formatMoney(num? value) {
    final safe = value ?? 0;
    final formatted = safe.toStringAsFixed(
      safe.truncateToDouble() == safe ? 0 : 2,
    );
    if (currency.trim().isEmpty) return formatted;
    return '$formatted $currency';
  }

  @override
  Widget build(BuildContext context) {
    final serviceAmount = useWorkerShare ? serviceShareAmount : basePrice;
    final totalAmount = useWorkerShare ? workerAmount : totalPrice;

    return Column(
      children: [
        _PaymentRow(
          label: 'سعر الخدمة',
          amount: _formatMoney(serviceAmount),
        ),
        12.verticalSpace,
        _PaymentRow(
          label: 'سعر التوصيل',
          amount: _formatMoney(travelFee),
          labelColor: context.primaryContainer,
          amountColor: context.primaryContainer,
        ),
        if (showAddonsTotal) ...[
          12.verticalSpace,
          _PaymentRow(
            label: 'إجمالي الإضافات',
            amount: _formatMoney(addonsTotal),
          ),
        ],
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
          label: useWorkerShare ? 'صافي أرباحك :' : 'الإجمالي',
          amount: _formatMoney(totalAmount),
          isTotal: true,
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
