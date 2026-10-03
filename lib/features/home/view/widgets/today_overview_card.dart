import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/worker_app_colors.dart';
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
            state.homePageUsecaseStatus == BlocStatus.loading ||
            state.homePageUsecaseStatus == BlocStatus.init;
        final isFailed = state.homePageUsecaseStatus == BlocStatus.failed;

        return Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WorkerAppRadius.lg),
            gradient: const LinearGradient(
              begin: AlignmentDirectional.bottomStart,
              end: AlignmentDirectional.topEnd,
              colors: [
                WorkerAppColors.brandPrimary,
                WorkerAppColors.brandPrimaryStrong,
                Color(0xFF3652B4),
              ],
              stops: [0, .72, 1],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ملخص اليوم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.cleaning_services_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'إجمالي الإيرادات',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE8EBFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (isLoading)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else if (isFailed)
                Text(
                  ErrorMessageFormatter.format(
                    state.errorMessage,
                    fallback: 'تعذر تحميل ملخص اليوم',
                  ),
                  style: const TextStyle(color: Colors.white),
                )
              else
                Text(
                  '${model?.totalEarnings.formatMoney(currency: '') ?? '0'} ل.س',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniMetric(
                    label: 'إجمالي الطلبات',
                    value: '${model?.totalBookings ?? 0}',
                  ),
                  const SizedBox(width: 8),
                  _MiniMetric(
                    label: 'المؤكدة',
                    value: '${model?.confirmedCount ?? 0}',
                  ),
                  const SizedBox(width: 8),
                  _MiniMetric(
                    label: 'المكتملة',
                    value: '${model?.completedCount ?? 0}',
                  ),
                ],
              ),
              if (state.homePageUsecaseStatus == BlocStatus.success &&
                  model?.blocksNewRequests == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(238),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: WorkerAppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          model!.eligibilityMessageAr,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: WorkerAppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(color: Color(0xFFDCE2FF), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
