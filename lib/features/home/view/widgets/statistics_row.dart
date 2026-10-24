import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
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
        final earnings = model?.totalEarnings;
        final earningsValue = earnings != null && earnings.isFinite
            ? earnings.formatMoney()
            : '—';

        final earningsCard = _StatCard(
          label: 'الإيرادات',
          value: loading ? '—' : earningsValue,
          icon: Icons.account_balance_wallet_outlined,
          color: WorkerAppColors.brandPrimary,
          onTap: onStatisticsTap,
        );
        final confirmedCard = _StatCard(
          label: 'المؤكدة',
          value: loading ? '—' : '${model?.confirmedCount ?? 0}',
          icon: Icons.event_available_rounded,
          color: WorkerAppColors.info,
          onTap: () => onStatusTap(CleaningBookingStatus.workerAssigned),
        );
        final completedCard = _StatCard(
          label: 'المكتملة',
          value: loading ? '—' : '${model?.completedCount ?? 0}',
          icon: Icons.task_alt_rounded,
          color: WorkerAppColors.success,
          onTap: () => onStatusTap(CleaningBookingStatus.completed),
        );
        if (MediaQuery.textScalerOf(context).scale(1) >= 1.2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              earningsCard,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: confirmedCard),
                  const SizedBox(width: 10),
                  Expanded(child: completedCard),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: earningsCard),
            const SizedBox(width: 10),
            Expanded(child: confirmedCard),
            const SizedBox(width: 10),
            Expanded(child: completedCard),
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
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: WorkerAppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: WorkerAppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
