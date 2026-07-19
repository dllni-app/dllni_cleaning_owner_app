import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class CalenderAppBar extends StatelessWidget {
  const CalenderAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(24.r),
          bottomLeft: Radius.circular(24.r),
        ),
        border: Border(bottom: BorderSide(color: context.primary, width: 5.w)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(27),
            offset: const Offset(0, -2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      width: context.width,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24.w, vertical: 16.h),
      child: AppText.headlineSmall(
        'تقويمي',
        fontWeight: FontWeight.w700,
        textAlign: TextAlign.start,
      ),
    );
  }
}
