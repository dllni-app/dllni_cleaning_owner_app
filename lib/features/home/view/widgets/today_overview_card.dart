import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../generated/assets.dart';
import '../manager/bloc/home_bloc.dart';

class TodayOverviewCard extends StatelessWidget {
  const TodayOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [context.primary, context.primary.withAlpha(127)],
          stops: [.8, 1],
          begin: AlignmentGeometry.bottomLeft,
          end: AlignmentGeometry.topRight,
        ),
      ),
      width: context.width,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge('إجمالي الايرادات', color: context.onPrimary, fontWeight: FontWeight.w400),
                SizedBox(height: 14),
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    switch (state.homePageUsecaseStatus) {
                      case null:
                        return Shimmer.fromColors(
                          baseColor: context.onPrimary,
                          highlightColor: context.primary,
                          child: Container(color: context.surface, height: 10, width: 100),
                        );
                      case BlocStatus.failed:
                        return AppText.labelMedium(state.errorMessage!, color: context.error);
                      case BlocStatus.success:
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AppText.displaySmall('${state.homePageUsecase?.totalEarnings}', color: context.onPrimary, fontWeight: FontWeight.bold),
                            SizedBox(width: 14,),
                            AppText.labelLarge('ل.س', color: context.primaryContainer, fontWeight: FontWeight.w400),
                          ],
                        );
                      case BlocStatus.loading:
                        return Shimmer.fromColors(
                          baseColor: context.onPrimary,
                          highlightColor: context.primary,
                          child: Container(color: context.surface, height: 10, width: 100),
                        );
                      case BlocStatus.init:
                        return Shimmer.fromColors(
                          baseColor: context.onPrimary,
                          highlightColor: context.primary,
                          child: Container(color: context.surface, height: 10, width: 100),
                        );
                    }
                  },
                ),
                AppImage.asset(Assets.images.homeChart.path),
              ],
            ),
          ),
          AppImage.asset(Assets.images.homeEarningIcon.path, size: 60,),
        ],
      ),
    );
  }
}
