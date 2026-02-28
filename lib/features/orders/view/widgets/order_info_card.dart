import 'package:common_package/common_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/fetch_orders_usecase_model.dart';

class OrderInfoCard extends StatelessWidget {
  const OrderInfoCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xffF4F5F7), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelMedium("حجز تنظيف منزل", fontWeight: FontWeight.w300),
              AppText.labelMedium(order.bookingNumber ?? '', fontWeight: FontWeight.w300),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.black.withAlpha(42)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tag, color: context.secondary, size: 18),
                  SizedBox(width: 6),
                  AppText.labelMedium("حالة الحجز", fontWeight: FontWeight.w400),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: Color(0xff00BA10).withAlpha(75), borderRadius: BorderRadius.circular(8)),
                child: AppText.labelMedium(order.status ?? '', fontWeight: FontWeight.w300),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: context.secondary, size: 18),
                  SizedBox(width: 6),
                  AppText.labelMedium("جدولة الحجز", fontWeight: FontWeight.w300),
                ],
              ),
              AppText.labelMedium(order.scheduledDate ?? '', fontWeight: FontWeight.w300),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: context.secondary, size: 18),
                  SizedBox(width: 6),
                  AppText.labelMedium("موعد الخدمة", fontWeight: FontWeight.w300),
                ],
              ),
              AppText.labelMedium(
                order.scheduledTime == null ? '' : DateFormat('hh:mm a').format(DateFormat("HH:mm:ss").parse(order.scheduledTime!)),
                fontWeight: FontWeight.w300,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
