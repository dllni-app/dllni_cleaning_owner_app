import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class OrderDetailsMapAppBar extends StatelessWidget {
  const OrderDetailsMapAppBar({super.key, required this.orderNum});

  final String orderNum;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        border: Border(bottom: BorderSide(color: context.primaryContainer, width: 3)),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24.r), bottomLeft: Radius.circular(24.r)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2.h), blurRadius: 12.r, spreadRadius: 0)],
      ),
      width: context.width,
      height: 70.h,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              context.pop();
            },
            child: Icon(Icons.arrow_back_ios_new, color: context.primary),
          ),
          8.horizontalSpace,
          Expanded(
            child: AppText.titleSmall('تفاصيل الطلب #$orderNum', color: context.primary, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
          ),
        ],
      ),
    );
  }
}
