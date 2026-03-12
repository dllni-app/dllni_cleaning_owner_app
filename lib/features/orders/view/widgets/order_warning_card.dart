import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class OrderWarningCard extends StatelessWidget {
  const OrderWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffEF6221).withAlpha(32),
        border: Border.all(color: Color(0xffEF6221)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsetsDirectional.all(16.r),
      margin: EdgeInsetsDirectional.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: context.onPrimary,
                child: Icon(Icons.access_time_filled, color: Color(0xffEF6221)),
              ),
              8.horizontalSpace,
              Expanded(
                child: AppText.labelLarge(
                  'يوجد لديك طلب تمديد المدة للعملية التي تقوم بتنفيذها رقم  #121.',
                  color: Color(0xffEF6221),
                  fontWeight: FontWeight.w400,
                  textAlign: TextAlign.start,
                ),
              ),
              8.horizontalSpace,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: context.onError,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(63), offset: Offset(0, 1.h), blurRadius: 2.r)],
                  ),
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 4.h),
                  child: AppText.labelMedium('مراجعة', color: Color(0xffEF6221), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
