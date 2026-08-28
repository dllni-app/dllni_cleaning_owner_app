import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_layout.dart';
import '../manager/bloc/home_bloc.dart';

class TodayOverviewCard extends StatelessWidget {
  const TodayOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final model = state.homePageUsecase;
        final isLoading =
            state.homePageUsecaseStatus == null ||
            state.homePageUsecaseStatus == BlocStatus.init ||
            state.homePageUsecaseStatus == BlocStatus.loading;
        final blocked = model?.blocksNewRequests == true;
        final isAdminSuspended =
            model?.dispatchEligibility?.isAdminSuspended == true;

        return Semantics(
          container: true,
          label: 'ملخص أرباح اليوم وحالة استقبال الطلبات',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            decoration: const BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
              boxShadow: AppShadows.floating,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إجمالي الأرباح',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          if (isLoading)
                            Shimmer.fromColors(
                              baseColor: Colors.white.withValues(alpha: 0.3),
                              highlightColor: Colors.white,
                              child: Container(
                                width: 148,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                              ),
                            )
                          else if (state.homePageUsecaseStatus ==
                              BlocStatus.failed)
                            Text(
                              'تعذّر تحميل الأرباح',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white),
                            )
                          else
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              spacing: AppSpace.xs,
                              children: [
                                Text(
                                  model?.totalEarnings.formatMoney(
                                        currency: '',
                                      ) ??
                                      '0',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                                Text(
                                  'ل.س',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        blocked
                            ? isAdminSuspended
                                  ? Icons.block_rounded
                                  : Icons.info_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blocked
                                  ? isAdminSuspended
                                        ? 'استقبال الطلبات متوقف إداريًا'
                                        : 'استقبال الطلبات متوقف مؤقتًا'
                                  : 'حسابك جاهز لاستقبال الطلبات',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            if (blocked &&
                                (model?.eligibilityMessageAr.isNotEmpty ??
                                    false)) ...[
                              const SizedBox(height: AppSpace.xxs),
                              Text(
                                model!.eligibilityMessageAr,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
