import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/fetch_notifications_model.dart';

class NotificationFeedItem extends StatelessWidget {
  const NotificationFeedItem({super.key, required this.notification});

  final FetchNotificationsModelDataItem notification;

  static String _normalizedCategory(FetchNotificationsModelDataItem n) {
    final c = (n.category ?? '').trim().toLowerCase();
    if (c.isNotEmpty) return c;
    final t = n.type.trim().toLowerCase();
    if (t.contains('order')) return 'orders';
    return 'system';
  }

  Color notificationStatusColor() {
    switch (_normalizedCategory(notification)) {
      case 'orders':
        return const Color(0xff10B981);
      case 'system':
        return const Color(0xff6B7280);
      default:
        return const Color(0xff6366F1);
    }
  }

  IconData notificationStatusIcon() {
    switch (_normalizedCategory(notification)) {
      case 'orders':
        return Icons.receipt_long_outlined;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  String _relativeTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(parsed.toLocal());

    if (diff.inMinutes < 1) {
      return 'الآن';
    }
    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    }
    if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    }
    if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    }
    return 'منذ أسبوع';
  }

  Widget _leadingIcon(BuildContext context) {
    final statusColor = notificationStatusColor();
    final url = (notification.icon ?? '').trim();
    if (url.isEmpty) {
      return Icon(notificationStatusIcon(), color: statusColor, size: 18);
    }
    final lower = url.toLowerCase();
    Widget child;
    if (lower.endsWith('.svg')) {
      child = SvgPicture.network(
        url,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(notificationStatusIcon(), color: statusColor, size: 18),
      );
    } else {
      child = Image.network(
        url,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(notificationStatusIcon(), color: statusColor, size: 18),
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isRead != true;

    return Container(
      color: context.onPrimary,
      child: Stack(
        children: [
          if (notification.showTrailingAccent)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(width: 3, color: context.primaryContainer),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _leadingIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUnread) ...[
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsetsDirectional.only(top: 7),
                              decoration: BoxDecoration(color: context.primaryContainer, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: AppText.bodyMedium(
                              notification.title ?? '',
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AppText.bodyMedium(notification.body ?? '', color: const Color(0xFF4B5563), textAlign: TextAlign.start),
                      const SizedBox(height: 4),
                      AppText.labelLarge(
                        _relativeTime(notification.createdAt),
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
