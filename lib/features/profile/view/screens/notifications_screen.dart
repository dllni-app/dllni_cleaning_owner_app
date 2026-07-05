import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/fetch_notifications_model.dart';
import '../../domain/usecases/fetch_notifications_use_case.dart';
import '../manager/bloc/profile_bloc.dart';
import '../widgets/notification_feed_item.dart';
import '../widgets/notification_navigation.dart';

@AutoRoutePage()
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _bucketLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);

    if (_isSameDay(today, target)) return 'اليوم';
    if (_isSameDay(today.subtract(const Duration(days: 1)), target)) {
      return 'أمس';
    }
    if (today.difference(target).inDays <= 7) return 'الأسبوع الماضي';
    return 'الأقدم';
  }

  Map<String, List<FetchNotificationsModelDataItem>> _groupNotifications(List<FetchNotificationsModelDataItem> notifications) {
    final grouped = <String, List<FetchNotificationsModelDataItem>>{'اليوم': [], 'أمس': [], 'الأسبوع الماضي': [], 'الأقدم': []};

    for (final item in notifications) {
      final parsed = DateTime.tryParse(item.createdAt ?? '');
      if (parsed == null) continue;
      grouped[_bucketLabel(parsed)]!.add(item);
    }

    return grouped;
  }

  Future<void> _refreshNotifications(BuildContext context) async {
    context.read<ProfileBloc>().add(FetchNotificationsEvent(params: FetchNotificationsParams(), isReload: true));
    await context.read<ProfileBloc>().stream.firstWhere((state) => state.notificationsStatus != BlocStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (_) => getIt<ProfileBloc>()..add(FetchNotificationsEvent(params: FetchNotificationsParams(), isReload: true)),
      child: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) {
          final listFailed = previous.notificationsStatus != current.notificationsStatus && current.notificationsStatus == BlocStatus.failed;
          final actionErr = (current.notificationActionError ?? '').isNotEmpty && current.notificationActionError != previous.notificationActionError;
          return listFailed || actionErr;
        },
        listener: (context, state) {
          final action = state.notificationActionError;
          if (action != null && action.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorMessageFormatter.format(action)),
              ),
            );
            return;
          }
          if (state.errorMessage == null || state.errorMessage!.isEmpty) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorMessageFormatter.format(state.errorMessage)),
            ),
          );
        },
        child: Scaffold(
          backgroundColor: const Color(0xffF9FAFB),
          body: SafeArea(
            child: Column(
              children: [
                const _NotificationsAppBar(),
                Expanded(
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final notifications = state.notifications;
                      final pagination = state.notificationsPagination;
                      final groups = _groupNotifications(state.notifications);
                      const sections = ['اليوم', 'أمس', 'الأسبوع الماضي', 'الأقدم'];
                      if (state.notificationsStatus == BlocStatus.loading && notifications.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (notifications.isEmpty) {
                        return const Center(child: Text('لا توجد إشعارات'));
                      }
                      return RefreshIndicator(
                        onRefresh: () async => await _refreshNotifications(context),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.pixels < notification.metrics.maxScrollExtent - 180) {
                              return false;
                            }
                            if (pagination.isEndPage || pagination.status == BlocStatus.loading) {
                              return false;
                            }
                            context.read<ProfileBloc>().add(FetchNotificationsEvent(params: FetchNotificationsParams(perPage: pagination.perPage), loadMore: true));
                            return false;
                          },
                          child: ListView(
                            padding: const EdgeInsetsDirectional.only(top: 8, bottom: 16),
                            children: [
                              for (final section in sections)
                                if (groups[section]!.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 8),
                                    child: AppText.labelLarge(section, color: const Color(0xff9CA3AF), fontWeight: FontWeight.w700, textAlign: TextAlign.start),
                                  ),
                                  Container(
                                    color: context.onPrimary,
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < groups[section]!.length; i++) ...[
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                final item = groups[section]![i];
                                                final id = item.id;
                                                if (id != null && id.isNotEmpty && item.isRead != true) {
                                                  context.read<ProfileBloc>().add(MarkNotificationReadEvent(id: id));
                                                }
                                                tryNavigateFromNotificationPayload(context, module: item.module, canonicalType: item.canonicalType, type: item.type, data: item.data);
                                              },
                                              child: NotificationFeedItem(notification: groups[section]![i]),
                                            ),
                                          ),
                                          if (i != groups[section]!.length - 1) const Divider(height: 1, thickness: 1, color: Color(0xffF3F4F6)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              if (!pagination.isEndPage && pagination.status == BlocStatus.loading)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsAppBar extends StatelessWidget {
  const _NotificationsAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: context.width,
      decoration: BoxDecoration(
        color: context.onPrimary,
        border: Border(bottom: BorderSide(color: context.primaryContainer, width: 2)),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(14), offset: const Offset(0, 3), blurRadius: 8)],
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.onPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE5E7EB)),
              ),
              child: Icon(Icons.arrow_back, color: context.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText.titleLarge('الإشعارات', color: context.primary, fontWeight: FontWeight.w700, textAlign: TextAlign.start),
          ),
          /*BlocBuilder<ProfileBloc, ProfileState>(
            buildWhen: (previous, current) =>
                previous.notifications != current.notifications || previous.markAllNotificationsReadStatus != current.markAllNotificationsReadStatus,
            builder: (context, state) {
              final hasUnread = state.notifications.any((e) => e.isRead != true);
              final loading = state.markAllNotificationsReadStatus == BlocStatus.loading;
              return TextButton(
                onPressed: !hasUnread || loading ? null : () => context.read<ProfileBloc>().add(MarkAllNotificationsReadEvent()),
                child: loading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.primary))
                    : AppText.labelLarge(
                        'تعليم الكل كمقروء',
                        color: hasUnread ? context.primary : const Color(0xff9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
              );
            },
          ),*/
        ],
      ),
    );
  }
}
