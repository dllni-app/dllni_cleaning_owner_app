import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../profile/view/manager/bloc/profile_bloc.dart';
import '../../../profile/view/screens/notifications_screen.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 80),
        padding: AppSpace.pagePadding(
          context,
        ).add(const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm)),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final profile = state.workerProfileUsecase?.data;
            final firstName = profile?.firstName?.trim() ?? '';
            final avatarUrl = profile?.avatar?.url;
            return Row(
              children: [
                Semantics(
                  image: true,
                  label: 'الصورة الشخصية',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? AppImage.network(avatarUrl, fit: BoxFit.cover)
                        : Icon(
                            Icons.person_outline_rounded,
                            color: colorScheme.primary,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName.isEmpty ? 'مرحبًا بك' : 'مرحبًا، $firstName',
                        maxLines: 2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        'هذه مهماتك وأرباحك اليوم',
                        maxLines: 2,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                _NotificationButton(
                  unreadCount: state.unreadNotification ?? 0,
                  onPressed: () {
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
            );
          },
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayCount = unreadCount > 99 ? '99+' : '$unreadCount';
    return Semantics(
      button: true,
      label: unreadCount > 0
          ? 'الإشعارات، $unreadCount غير مقروءة'
          : 'الإشعارات، لا توجد إشعارات غير مقروءة',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton.filledTonal(
            tooltip: 'عرض الإشعارات',
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          if (unreadCount > 0)
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Text(
                  displayCount,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onError,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
