import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_layout.dart';
import '../manager/bloc/profile_bloc.dart';
import 'circular_star_rating.dart';

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 132),
      padding: AppSpace.pagePadding(
        context,
      ).add(const EdgeInsetsDirectional.symmetric(vertical: AppSpace.lg)),
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.workerProfileUsecaseStatus == BlocStatus.loading ||
              state.workerProfileUsecaseStatus == BlocStatus.init) {
            return _loading(context);
          }
          final data = state.workerProfileUsecase?.data;
          final avatarUrl = data?.avatar?.url?.trim() ?? '';
          final name = data?.user?.name?.trim();
          return Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl.isEmpty
                    ? const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: AppIconSize.xl,
                      )
                    : Image.network(avatarUrl, fit: BoxFit.cover),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(
                      name == null || name.isEmpty ? 'عامل دللني' : name,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        'ID: ${data?.user?.id ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CircularStarRating(rating: data?.averageRating ?? 0),
            ],
          );
        },
      ),
    );
  }

  Widget _loading(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.2),
      highlightColor: Colors.white.withValues(alpha: 0.7),
      child: Row(
        children: [
          const CircleAvatar(radius: 34, backgroundColor: Colors.white),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 18, color: Colors.white),
                const SizedBox(height: AppSpace.sm),
                Container(width: 80, height: 12, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
