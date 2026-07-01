import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:easy_localization/easy_localization.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelLarge(
                      'إجمالي الايرادات',
                      color: context.onPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: 14),
                    BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, state) {
                        switch (state.homePageUsecaseStatus) {
                          case null:
                            return Shimmer.fromColors(
                              baseColor: context.onPrimary,
                              highlightColor: context.primary,
                              child: Container(
                                color: context.surface,
                                height: 10,
                                width: 100,
                              ),
                            );
                          case BlocStatus.failed:
                            return AppText.labelMedium(
                              state.errorMessage!.tr(),
                              color: context.error,
                            );
                          case BlocStatus.success:
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                AppText.displaySmall(
                                  state.homePageUsecase?.totalEarnings.formatMoney(currency: '')??'0 ل.س',
                                  color: context.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(width: 14),
                                AppText.labelLarge(
                                  'ل.س',
                                  color: context.primaryContainer,
                                  fontWeight: FontWeight.w400,
                                ),
                              ],
                            );
                          case BlocStatus.loading:
                            return Shimmer.fromColors(
                              baseColor: context.onPrimary,
                              highlightColor: context.primary,
                              child: Container(
                                color: context.surface,
                                height: 10,
                                width: 100,
                              ),
                            );
                          case BlocStatus.init:
                            return Shimmer.fromColors(
                              baseColor: context.onPrimary,
                              highlightColor: context.primary,
                              child: Container(
                                color: context.surface,
                                height: 10,
                                width: 100,
                              ),
                            );
                        }
                      },
                    ),
                    AppImage.asset(Assets.images.homeChart.path),
                  ],
                ),
              ),
              AppImage.asset(Assets.images.homeEarningIcon.path, size: 60),
            ],
          ),
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (previous, current) =>
            previous.homePageUsecase?.blocksNewRequests !=
                current.homePageUsecase?.blocksNewRequests ||
                previous.homePageUsecaseStatus != current.homePageUsecaseStatus,
            builder: (context, state) {
              final model = state.homePageUsecase;
              if (state.homePageUsecaseStatus != BlocStatus.success ||
                  model?.blocksNewRequests != true) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsetsDirectional.only(top: 12),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(235),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: context.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.labelLarge(
                            'ملاحظة على استقبال الطلبات',
                            color: context.error,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 4),
                          AppText.bodySmall(
                            model!.eligibilityMessageAr,
                            color: const Color(0xff374151),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
