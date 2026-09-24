import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/worker_app_colors.dart';
import '../../../../core/widgets/worker_surface_card.dart';
import '../../../orders/data/models/cleaning_booking_status.dart';
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
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final model = state.homePageUsecase;
        final loading =
            state.homePageUsecaseStatus == null ||
            state.homePageUsecaseStatus == BlocStatus.loading ||
            state.homePageUsecaseStatus == BlocStatus.init;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'الإيرادات',
                value: loading ? '—' : '${model?.totalEarnings ?? 0}',
                icon: Icons.account_balance_wallet_outlined,
                color: WorkerAppColors.brandPrimary,
                onTap: onStatisticsTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'المؤكدة',
                value: loading ? '—' : '${model?.confirmedCount ?? 0}',
                icon: Icons.event_available_rounded,
                color: WorkerAppColors.info,
                onTap: () => onStatusTap(CleaningBookingStatus.workerAssigned),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'المكتملة',
                value: loading ? '—' : '${model?.completedCount ?? 0}',
                icon: Icons.task_alt_rounded,
                color: WorkerAppColors.success,
                onTap: () => onStatusTap(CleaningBookingStatus.completed),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WorkerSurfaceCard(
      onTap: onTap,
      radius: WorkerAppRadius.md,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: WorkerAppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: WorkerAppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
