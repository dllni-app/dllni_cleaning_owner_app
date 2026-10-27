import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/worker_app_colors.dart';

/// Only worker-facing earnings. Every amount is supplied by the backend.
class WorkerPaymentSummary extends StatelessWidget {
  const WorkerPaymentSummary({
    super.key,
    required this.basePrice,
    this.bookingBasePrice,
    this.bookingServicePriceIncludingAdmin,
    this.bookingAdminMargin,
    required this.travelFee,
    required this.adminMargin,
    required this.addonsTotal,
    required this.totalPrice,
    this.showAddonsTotal = true,
    this.serviceShareAmount,
    this.workerAmount,
    this.useWorkerShare = false,
    this.baseServiceShareAmount,
    this.serviceAndOperationalShareAmount,
    this.specialServicesShareAmount,
    this.materialsShareAmount,
    this.adminMarginPercentage,
    this.plannedWorkerCount,
    this.actualWorkerCount,
    this.isFinal = false,
    this.hideGroupMaterialPrices = false,
  });

  final num? basePrice;
  final num? bookingBasePrice;
  final num? bookingServicePriceIncludingAdmin;
  final num? bookingAdminMargin;
  final num? travelFee;
  final num? adminMargin;
  final num? addonsTotal;
  final num? totalPrice;
  final bool showAddonsTotal;
  final num? serviceShareAmount;
  final num? workerAmount;
  final bool useWorkerShare;
  final num? baseServiceShareAmount;
  final num? serviceAndOperationalShareAmount;
  final num? specialServicesShareAmount;
  final num? materialsShareAmount;
  final num? adminMarginPercentage;
  final int? plannedWorkerCount;
  final int? actualWorkerCount;
  final bool isFinal;
  final bool hideGroupMaterialPrices;

  static String _money(num? value) => value == null
      ? 'قيد التحديد'
      : '${NumberFormat('#,##0.##').format(value)} ل.س';

  @override
  Widget build(BuildContext context) {
    // Prefer the backend's complete per-worker service share (including
    // applicable special services) over a partial base-service breakdown.
    // Never substitute booking-level amounts for a worker's share.
    final serviceAmount = useWorkerShare
        ? serviceShareAmount ??
              serviceAndOperationalShareAmount ??
              baseServiceShareAmount
        : basePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaymentRow(label: 'حصتك من الخدمة', amount: _money(serviceAmount)),
        const SizedBox(height: 12),
        _PaymentRow(label: 'بدل المواصلات', amount: _money(travelFee)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: WorkerAppColors.brandPrimarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD5DCF6)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: WorkerAppColors.brandPrimary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isFinal ? 'مستحقك النهائي' : 'مستحقك الحالي',
                  style: const TextStyle(
                    color: WorkerAppColors.brandPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _money(workerAmount),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: WorkerAppColors.brandPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: WorkerAppColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        amount,
        textAlign: TextAlign.end,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: WorkerAppColors.textPrimary,
        ),
      ),
    ],
  );
}
