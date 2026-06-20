import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../generated/assets.dart';
import '../manager/bloc/home_bloc.dart';

class StatisticsRow extends StatelessWidget {
  const StatisticsRow({
    super.key,
    required this.onStatusTap,
    required this.onStatisticsTap,
  });

  final ValueChanged<String> onStatusTap;
  final VoidCallback onStatisticsTap;

  @override
  Widget build(BuildContext context) {
    List<Color> colors = [
      Color(0xff2C3997),
      Color(0xffEF6221),
      Color(0xff00BA10),
    ];
    List<String> titles = ['إجمالي الطلبات', 'قيد التنفيذ', 'طلبات مكتملة'];
    List<String> images = [
      Assets.images.homeNewOrdersIcon.path,
      Assets.images.homeConfirmedOrdersIcon.path,
      Assets.images.homeCompletedOrdersIcon.path,
    ];
    List<String> statuses = [
      CleaningBookingStatus.inProgress,
      CleaningBookingStatus.completed,
    ];

    return Row(
      spacing: 24.w,
      children: List.generate(3, (i) {
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: i == 0
                ? onStatisticsTap
                : () => onStatusTap(statuses[i - 1]),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border(
                  bottom: BorderSide(color: colors[i], width: 2.w),
                ),
                color: context.onPrimary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(63),
                    offset: Offset(0, 2.h),
                    blurRadius: 4.r,
                  ),
                ],
              ),
              padding: EdgeInsetsDirectional.symmetric(vertical: 14.h),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 15.r,
                    backgroundColor: colors[i].withAlpha(51),
                    child: AppImage.asset(
                      images[i],
                      size: 15.r,
                      color: colors[i],
                    ),
                  ),
                  14.verticalSpace,
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      switch (state.homePageUsecaseStatus) {
                        case null:
                          return Shimmer.fromColors(
                            baseColor: context.onPrimary,
                            highlightColor: context.primary,
                            child: Container(
                              color: context.surface,
                              height: 20.h,
                              width: 20.w,
                            ),
                          );
                        case BlocStatus.failed:
                          return CircleAvatar(
                            radius: 15.r,
                            backgroundColor: context.surface,
                            child: AppText.labelMedium('0'),
                          );
                        case BlocStatus.success:
                          final value = i == 0
                              ? state.homePageUsecase!.totalBookings
                              : i == 1
                              ? state.homePageUsecase!.inProgressCount
                              : state.homePageUsecase!.completedCount;
                          return AppText.labelLarge('${value ?? 0}');
                        case BlocStatus.loading:
                          return Shimmer.fromColors(
                            baseColor: context.onPrimary,
                            highlightColor: context.primary,
                            child: Container(
                              color: context.surface,
                              height: 20.h,
                              width: 20.w,
                            ),
                          );
                        case BlocStatus.init:
                          return Shimmer.fromColors(
                            baseColor: context.onPrimary,
                            highlightColor: context.primary,
                            child: Container(
                              color: context.surface,
                              height: 20.h,
                              width: 20.w,
                            ),
                          );
                      }
                    },
                  ),
                  14.verticalSpace,
                  AppText.labelMedium(
                    titles[i],
                    fontWeight: FontWeight.w500,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
