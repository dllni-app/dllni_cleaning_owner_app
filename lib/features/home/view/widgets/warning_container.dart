import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class WarningContainer extends StatelessWidget {
  const WarningContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.error.withAlpha(32),
        border: Border.all(color: context.error),
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsetsDirectional.all(16.r),
      child: Center(
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: context.onPrimary,
              child: Icon(Icons.warning, color: context.error),
            ),
            8.horizontalSpace,
            Expanded(
              child: AppText.labelLarge(
                'يوجد لديك طلب يجب عليك مراجعته',
                color: context.error,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.start,
              ),
            ),
            8.horizontalSpace,
            InkWell(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: context.onError,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(63), offset: Offset(0, 1.h), blurRadius: 2.r)],
                ),
                padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 4.h),
                child: AppText.labelMedium('مراجعة', color: context.error, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
