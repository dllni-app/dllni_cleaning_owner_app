import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../generated/assets.dart';
import '../../../orders/data/models/fetch_orders_usecase_model.dart';
import '../../../orders/view/screens/order_details_screen.dart';

class CalenderOrderCard extends StatelessWidget {
  const CalenderOrderCard({super.key, required this.date, required this.index});

  final FetchOrdersUsecaseModelDataItem date;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52.w,
          child: AppText.labelMedium(
            CleaningArabicTimeFormatter.formatScheduledTime(
              date.scheduledTime,
              emptyValue: '',
            ),
            scrollText: true,
          ),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: InkWell(
            onTap: () {
              context.pushRoute('/orderdetails', arguments: OrderDetailsScreenParams(
                bloc: context.read<OrdersBloc>(),
                index: index,
                order: date,
                isNewOrder: false,
              ));
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              decoration: BoxDecoration(
                color: context.onPrimary,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                      child: AppText.labelLarge(
                        date.locationName ?? '',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Divider(height: 1, color: context.surface),
                    SizedBox(height: 12.h),
                    dataRow(
                      Assets.images.orderCardCalender.path,
                      'جدولة الحجز',
                      CleaningArabicTimeFormatter.formatCalendarIsoDate(
                        date.scheduledDate,
                        emptyValue: '',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    dataRow(
                      Assets.images.orderCardBuilding.path,
                      'نوع العقار',
                      date.propertyType ?? '',
                    ),
                    SizedBox(height: 12.h),
                    dataRow(
                      Assets.images.orderCardAlarm.path,
                      'المساحة التقديرية',
                      date.estimatedSqm == null || date.estimatedSqm!.isEmpty
                          ? ''
                          : '${CleaningArabicTimeFormatter.toArabicDigits(date.estimatedSqm!)} متر مربع',
                    ),
                    SizedBox(height: 12.h),
                    Divider(height: 1, color: context.surface),
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          date.customer?.phone == null
                              ? const SizedBox.shrink()
                              : InkWell(
                                  onTap: () async {
                                    callPhone(date.customer!.phone!);
                                  },
                                  child: CircleAvatar(
                                    radius: 15.r,
                                    backgroundColor: context.primaryContainer,
                                    child: Icon(
                                      Icons.phone_outlined,
                                      color: context.onPrimaryContainer,
                                      size: 15.sp,
                                    ),
                                  ),
                                ),
                          AppText.titleSmall(
                            '${CleaningArabicTimeFormatter.toArabicDigits(date.totalPrice?.toString() ?? '')} ل.س',
                            color: context.primaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> callPhone(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget dataRow(image, title, data) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          AppImage.asset(image, size: 15),
          SizedBox(width: 8.w),
          AppText.labelMedium(title, fontWeight: FontWeight.w300),
          const Spacer(),
          Flexible(
            child: AppText.labelMedium(
              data,
              fontWeight: FontWeight.w300,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
