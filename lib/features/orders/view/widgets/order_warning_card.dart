import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/theme/worker_app_colors.dart';

class OrderWarningCard extends StatelessWidget {
  const OrderWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WorkerAppColors.warningSoft,
        border: Border.all(color: WorkerAppColors.warning),
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
                child: Icon(
                  Icons.access_time_filled,
                  color: WorkerAppColors.warning,
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: AppText.labelLarge(
                  'يوجد لديك طلب تمديد المدة للعملية التي تقوم بتنفيذها رقم  #121.',
                  color: WorkerAppColors.warning,
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(63),
                        offset: Offset(0, 1.h),
                        blurRadius: 2.r,
                      ),
                    ],
                  ),
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  child: AppText.labelMedium(
                    'مراجعة',
                    color: WorkerAppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
