import 'package:common_package/common_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../generated/assets.dart';
import '../../../orders/data/models/fetch_orders_usecase_model.dart';

class CalenderOrderCard extends StatelessWidget {
  const CalenderOrderCard({super.key, required this.date});

  final FetchOrdersUsecaseModelDataItem date;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: AppText.labelMedium(DateFormat('hh:mm a').format(DateFormat("HH:mm:ss").parse(date.scheduledTime!)), scrollText: true),
        ),
        SizedBox(width: 13),
        Expanded(
          child: InkWell(
            onTap: () {
              context.pushRoute('/orderdetails', arguments: date);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(color: context.onPrimary, borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
                      child: AppText.labelLarge(date.locationName ?? '', fontWeight: FontWeight.w400),
                    ),
                    SizedBox(height: 12),
                    Divider(height: 1, color: context.surface),
                    SizedBox(height: 12),
                    dataRow(Assets.images.orderCardCalender.path, 'جدولة الحجز', date.scheduledDate ?? ''),
                    SizedBox(height: 12),
                    dataRow(Assets.images.orderCardBuilding.path, 'نوع العقار', date.propertyType ?? ''),
                    SizedBox(height: 12),
                    dataRow(Assets.images.orderCardAlarm.path, 'المساحة التقديرية', date.estimatedSqm == null ? '' : '${date.estimatedSqm} متر مربع'),
                    SizedBox(height: 12),
                    Divider(height: 1, color: context.surface),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          date.customer?.phone == null
                              ? SizedBox.shrink()
                              : InkWell(
                                  onTap: () async {
                                    callPhone(date.customer!.phone!);
                                  },
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: context.primaryContainer,
                                    child: Icon(Icons.phone_outlined, color: context.onPrimaryContainer, size: 15),
                                  ),
                                ),
                          AppText.titleSmall('${date.totalPrice} ل.س', color: context.primaryContainer),
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
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
      child: Row(
        children: [
          AppImage.asset(image, size: 15),
          SizedBox(width: 8),
          AppText.labelMedium(title, fontWeight: FontWeight.w300),
          Spacer(),
          AppText.labelMedium(data, fontWeight: FontWeight.w300),
        ],
      ),
    );
  }
}
