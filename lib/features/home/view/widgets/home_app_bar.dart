import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/worker_app_colors.dart';
import '../../../../core/widgets/worker_screen_header.dart';
import '../../../profile/view/manager/bloc/profile_bloc.dart';
import '../../../profile/view/screens/notifications_screen.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final data = state.workerProfileUsecase?.data;
        final firstName = (data?.firstName ?? data?.user?.name ?? '').trim();
        final unread = state.unreadNotification ?? 0;
        final avatar = data?.avatar?.url;

        return Container(
          color: WorkerAppColors.surface,
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
          child: Row(
            children: [
              _WorkerAvatar(url: avatar, name: firstName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isEmpty ? 'مرحباً' : 'مرحباً، $firstName',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: WorkerAppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'جاهز لمهام اليوم؟',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WorkerAppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              WorkerHeaderAction(
                icon: Icons.notifications_none_rounded,
                badge: unread <= 0 ? null : (unread > 99 ? '99+' : '$unread'),
                semanticLabel: 'الإشعارات',
                onTap: () {
                  final profileBloc = context.read<ProfileBloc>();
                  context.pushRoute(
                    '/notifications',
                    arguments: NotificationsScreenParams(
                      profileBloc: profileBloc,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkerAvatar extends StatelessWidget {
  const _WorkerAvatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'ع' : name.trim().characters.first;
    if (url != null && url!.trim().isNotEmpty) {
      return AppImage.network(
        url!,
        borderRadius: BorderRadius.circular(999),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: WorkerAppColors.brandPrimarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: WorkerAppColors.brandPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
