import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../data/models/fetch_orders_usecase_model.dart';

class EstateInfoCard extends StatefulWidget {
  const EstateInfoCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  State<EstateInfoCard> createState() => _EstateInfoCardState();
}

class _EstateInfoCardState extends State<EstateInfoCard> {
  List<String> attributes = [];
  @override
  void initState() {
    super.initState();
    attributes = [
      '${widget.order.propertyDetails?.bathrooms ?? 0} حمام',
      '${widget.order.propertyDetails?.bedRooms ?? 0} غرف نوم',
      if (widget.order.propertyDetails?.kitchen == true) 'مطبخ',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(color: Color(0xffF4F5F7), borderRadius: BorderRadius.circular(20.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [AppText.labelMedium("معلومات العقار", fontWeight: FontWeight.w400)],
          ),
          12.verticalSpace,
          Divider(color: Colors.black.withAlpha(42)),
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.apartment, color: context.secondary, size: 18.sp),
                  6.horizontalSpace,
                  AppText.labelMedium("نوع العقار", fontWeight: FontWeight.w400),
                ],
              ),
              AppText.labelMedium(widget.order.locationName ?? '', fontWeight: FontWeight.w300),
            ],
          ),
          14.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.square_foot, color: context.secondary, size: 18.sp),
                  6.horizontalSpace,
                  AppText.labelMedium("المساحة التقديرية", fontWeight: FontWeight.w400),
                ],
              ),
              AppText.labelMedium('${widget.order.estimatedSqm} متر مربع', fontWeight: FontWeight.w300),
            ],
          ),
          18.verticalSpace,
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: List.generate(attributes.length, (i) => _buildFeatureChip(attributes[i], context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: context.secondary.withAlpha(40), borderRadius: BorderRadius.circular(12.r)),
      child: AppText.labelMedium(text, fontWeight: FontWeight.w300, color: context.secondary),
    );
  }
}
