import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/worker_app_colors.dart';
import '../../../../core/widgets/worker_surface_card.dart';
import '../manager/bloc/profile_bloc.dart';
import 'circular_star_rating.dart';

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: WorkerAppColors.surface,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 14),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          switch (state.workerProfileUsecaseStatus) {
            case BlocStatus.success:
              final profile = state.workerProfileUsecase?.data;
              final name = profile?.user?.name ?? '-';
              final id = profile?.user?.id;
              return WorkerSurfaceCard(
                shadow: false,
                radius: WorkerAppRadius.lg,
                backgroundColor: WorkerAppColors.brandPrimary,
                borderColor: WorkerAppColors.brandPrimary,
                padding: const EdgeInsetsDirectional.all(16),
                child: Row(
                  children: [
                    _Avatar(url: profile?.avatar?.url, name: name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${id ?? '-'}',
                            textDirection: TextDirection.ltr,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: const Color(0xFFDCE2FF),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    CircularStarRating(rating: profile?.averageRating ?? 0),
                  ],
                ),
              );
            case BlocStatus.loading:
            case BlocStatus.init:
              return _loading(context);
            case BlocStatus.failed:
            case null:
              return _failed(context);
          }
        },
      ),
    );
  }

  Widget _loading(BuildContext context) => WorkerSurfaceCard(
    shadow: false,
    backgroundColor: WorkerAppColors.brandPrimary,
    borderColor: WorkerAppColors.brandPrimary,
    child: Row(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.white24,
          highlightColor: Colors.white54,
          child: const CircleAvatar(radius: 25, backgroundColor: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_line(120), const SizedBox(height: 10), _line(80)],
          ),
        ),
      ],
    ),
  );

  Widget _line(double width) => Shimmer.fromColors(
    baseColor: Colors.white24,
    highlightColor: Colors.white54,
    child: Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );

  Widget _failed(BuildContext context) => WorkerSurfaceCard(
    shadow: false,
    backgroundColor: WorkerAppColors.brandPrimary,
    borderColor: WorkerAppColors.brandPrimary,
    child: Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white24,
          child: Icon(Icons.person_outline_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062e\u0635\u064a',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.trim().isNotEmpty) {
      return AppImage.network(
        url!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(999),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white24,
      child: Text(
        name.trim().isEmpty ? '\u0639' : name.trim().characters.first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
