import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/widgets/provisional_pricing_notice.dart';
import '../../data/models/fetch_orders_usecase_model.dart';

class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  bool get _usesWorkerShare => order.myAssignment != null;

  String? get _serviceShareLabel {
    final amount = order.myAssignment?.serviceShareAmount;
    if (amount == null) return null;
    return amount.toString();
  }

  String? get _travelFeeLabel {
    final amount = order.myAssignment?.travelFee ?? order.travelFee;
    if (amount == null) return null;
    return amount.toString();
  }

  String get _totalLabel {
    if (_usesWorkerShare) {
      final amount = order.myAssignment?.workerAmount;
      if (amount == null) return '';
      final currency = order.myAssignment?.currency;
      return currency == null || currency.isEmpty ? '\$$amount' : '$amount $currency';
    }
    return order.totalPrice == null ? '' : '\$${order.totalPrice}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(color: Color(0xffF4F5F7), borderRadius: BorderRadius.circular(20.r)),
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
          if (_usesWorkerShare && _serviceShareLabel != null) ...[
            _buildPriceRow(title: 'حصة الخدمة', price: _serviceShareLabel!),
            12.verticalSpace,
          ] else ...[
            _buildPriceRow(
              title: 'سعر الخدمة الأساس',
              price: order.basePrice == null ? '' : order.basePrice.toString(),
            ),
            12.verticalSpace,
          ],
          if (_travelFeeLabel != null)
            _buildPriceRow(
              title: 'رسوم توصيل',
              price: _travelFeeLabel!,
              titleColor: context.primaryContainer,
              priceColor: context.primaryContainer,
            ),
          if (_travelFeeLabel != null) 18.verticalSpace,
          LayoutBuilder(
            builder: (context, constraints) {
              final dashWidth = 6.0.w;
              final dashSpace = 6.0.w;
              final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(dashCount, (_) {
                  return Container(width: dashWidth, height: 2.h, color: context.primaryContainer);
                }),
              );
            },
          ),
          18.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelMedium(
                _usesWorkerShare ? 'صافي أرباحك :' : 'المبلغ الكلي :',
                fontWeight: FontWeight.w500,
              ),
              AppText.labelMedium(_totalLabel, fontWeight: FontWeight.w600),
            ],
          ),
          if (order.isPricingFinal == false) ...[
            12.verticalSpace,
            const ProvisionalPricingNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow({required String title, required String price, Color? titleColor, Color? priceColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: AppText.labelMedium(title, fontWeight: FontWeight.w400, color: titleColor),
          ),
        ),
        AppText.labelMedium(price, fontWeight: FontWeight.w400, color: priceColor),
      ],
    );
  }
}
