import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../generated/assets.dart';
import '../manager/bloc/home_bloc.dart';

class StatisticsRow extends StatelessWidget {
  const StatisticsRow({super.key});

  @override
  Widget build(BuildContext context) {
    List<Color> colors = [Color(0xff2C3997), Color(0xffEF6221), Color(0xff00BA10)];
    List<String> titles = ['طلبات جديدة', 'طلبات مؤكدة', 'طلبات مكتملة'];
    List<String> images = [Assets.images.homeNewOrdersIcon.path, Assets.images.homeConfirmedOrdersIcon.path, Assets.images.homeCompletedOrdersIcon.path];

    return Row(
      spacing: 24.w,
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border(bottom: BorderSide(color: colors[i], width: 2.w)),
              color: context.onPrimary,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(63), offset: Offset(0, 2.h), blurRadius: 4.r)],
            ),
            padding: EdgeInsetsDirectional.symmetric(vertical: 14.h),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15.r,
                  backgroundColor: colors[i].withAlpha(51),
                  child: AppImage.asset(images[i], size: 15.r, color: colors[i]),
                ),
                14.verticalSpace,
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    switch (state.homePageUsecaseStatus) {
                      case null:
                        return Shimmer.fromColors(
                          baseColor: context.onPrimary,
                          highlightColor: context.primary,
                          child: Container(color: context.surface, height: 20.h, width: 20.w),
                        );
                      case BlocStatus.failed:
                        return CircleAvatar(radius: 15.r, backgroundColor: context.surface, child: AppText.labelMedium('0'));
                      case BlocStatus.success:
                        final value = i == 0
                            ? state.homePageUsecase!.newOrdersCount
                            : i == 1
                            ? state.homePageUsecase!.inProgressCount
                            : state.homePageUsecase!.completedCount;
                        return AppText.labelLarge('${value ?? 0}');
                      case BlocStatus.loading:
                        return Shimmer.fromColors(
                          baseColor: context.onPrimary,
                          highlightColor: context.primary,
                          child: Container(color: context.surface, height: 20.h, width: 20.w),
                        );
                      case BlocStatus.init:
                        return Shimmer.fromColors(
                          baseColor: context.onPrimary,
                          highlightColor: context.primary,
                          child: Container(color: context.surface, height: 20.h, width: 20.w),
                        );
                    }
                  },
                ),
                14.verticalSpace,
                AppText.labelMedium(titles[i], fontWeight: FontWeight.w500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
