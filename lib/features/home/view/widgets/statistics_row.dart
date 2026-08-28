import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../core/widgets/app_surface_card.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 1;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * AppSpace.sm) / columns;
        return Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            _MetricCard(
              width: cardWidth,
              title: 'كل الطلبات',
              icon: Icons.receipt_long_outlined,
              value: (state) => state.homePageUsecase?.totalBookings,
              onTap: onStatisticsTap,
            ),
            _MetricCard(
              width: cardWidth,
              title: 'طلبات مؤكدة',
              icon: Icons.event_available_outlined,
              value: (state) => state.homePageUsecase?.confirmedCount,
              onTap: () => onStatusTap(CleaningBookingStatus.workerAssigned),
            ),
            _MetricCard(
              width: cardWidth,
              title: 'طلبات مكتملة',
              icon: Icons.task_alt_rounded,
              value: (state) => state.homePageUsecase?.completedCount,
              onTap: () => onStatusTap(CleaningBookingStatus.completed),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final double width;
  final String title;
  final IconData icon;
  final int? Function(HomeState) value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: AppSurfaceCard(
        onTap: onTap,
        semanticLabel: title,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: colorScheme.secondary),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      final loading =
                          state.homePageUsecaseStatus == null ||
                          state.homePageUsecaseStatus == BlocStatus.init ||
                          state.homePageUsecaseStatus == BlocStatus.loading;
                      if (loading) {
                        return Shimmer.fromColors(
                          baseColor: colorScheme.surfaceContainerHighest,
                          highlightColor: colorScheme.surface,
                          child: Container(
                            width: 48,
                            height: 24,
                            color: colorScheme.surface,
                          ),
                        );
                      }
                      return Text(
                        '${value(state) ?? 0}',
                        style: Theme.of(context).textTheme.titleLarge,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: AppIconSize.sm,
              color: colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
