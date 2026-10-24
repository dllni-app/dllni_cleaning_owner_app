import 'package:flutter/material.dart';
import '../../contracts/fixtures/base_fixtures.dart';
import '../design_system.dart';

/// Static, fixture-driven examples for review; no operational navigation.
class WrComponentGallery extends StatelessWidget {
  const WrComponentGallery({super.key, required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final active = BaseFixtures.scenarios.firstWhere(
      (value) => value.code == 'legacy_single_worker',
    );
    final next = BaseFixtures.scenarios.firstWhere(
      (value) => value.code == 'independent_later_visit',
    );
    final intervals = BaseFixtures.scenarios
        .firstWhere((value) => value.code == 'room_interval_overlap_gap')
        .intervals;
    final supervised = BaseFixtures.scenarios.firstWhere(
      (value) => value.code == 'standard_kind_supervisor_v2',
    );
    final zero = BaseFixtures.scenarios.firstWhere(
      (value) => value.code == 'valid_zero_money',
    );
    final unknown = BaseFixtures.scenarios.firstWhere(
      (value) => value.code == 'missing_allocation',
    );
    final usd = BaseFixtures.scenarios.firstWhere(
      (value) => value.code == 'mixed_currencies',
    );
    String tr(String ar, String en) => arabic ? ar : en;
    String utcInterval(int index) {
      final interval = intervals[index];
      return '${interval.start.substring(11, 16)} – '
          '${interval.end.substring(11, 16)} UTC';
    }

    return WrPageFrame(
      title: tr('مكونات تطبيق العامل', 'Worker UI components'),
      subtitle: tr(
        'أمثلة تجريبية بدون بيانات حقيقية',
        'Synthetic, display-only examples',
      ),
      // The lengthy component examples precede the fixed navigation gallery.
      // ignore: sort_child_properties_last
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WrSectionPanel(
            title: tr('اليوم', 'Today'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WrListRow(
                  title: tr('العمل الحالي', 'Current work'),
                  subtitle: tr(
                    'طلب ${active.scope.bookingId} • الوقت غير مؤكد',
                    'Booking ${active.scope.bookingId} • time unconfirmed',
                  ),
                  leading: const Icon(Icons.play_circle_outline),
                  trailing: WrStatusBadge(
                    label: tr('نشط', 'Active'),
                    tone: WrStatusTone.success,
                  ),
                ),
                const Divider(),
                WrListRow(
                  title: tr('الزيارة التالية', 'Next visit'),
                  subtitle: tr(
                    'زيارة ${next.scope.sessionId} • الموعد غير مؤكد',
                    'Visit ${next.scope.sessionId} • time unconfirmed',
                  ),
                  leading: const Icon(Icons.event_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: WrSpace.md),
          WrSectionPanel(
            title: tr('جدول الغرف', 'Room schedule'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WrListRow(
                  title: tr('مثال غرفة 1', 'Sample room 1'),
                  subtitle: utcInterval(0),
                  subtitleDirection: TextDirection.ltr,
                ),
                WrListRow(
                  title: tr('مثال غرفة 2 • تداخل', 'Sample room 2 • overlap'),
                  subtitle: utcInterval(1),
                  subtitleDirection: TextDirection.ltr,
                ),
                Text(
                  tr(
                    'يوجد فاصل قبل الفترة التالية',
                    'Gap before the following interval',
                  ),
                  style: WrType.support,
                ),
                WrListRow(
                  title: tr('مثال غرفة 3', 'Sample room 3'),
                  subtitle: utcInterval(2),
                  subtitleDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          const SizedBox(height: WrSpace.md),
          WrSectionPanel(
            title: tr('المهمة', 'Mission'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WrEligibilityNotice(
                  title: tr(
                    'المشرف يدير التنفيذ',
                    'Supervisor manages execution',
                  ),
                  message: tr(
                    'يمكنك تسجيل الحضور، والتنفيذ بيد المشرف.',
                    'Attendance remains available; execution belongs to the supervisor.',
                  ),
                ),
                const SizedBox(height: WrSpace.sm),
                WrActionButton(
                  label: tr(
                    'عرض الزيارة ${supervised.scope.sessionId}',
                    'View visit ${supervised.scope.sessionId}',
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: WrSpace.md),
          WrSectionPanel(
            title: tr('الأرباح المكتملة', 'Completed earnings'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WrListRow(
                  title: tr('مبلغ مؤكد صفري', 'Confirmed zero amount'),
                  trailing: WrAmountText(
                    amount: zero.money,
                    unavailableLabel: tr('غير متاح', 'Unavailable'),
                  ),
                ),
                const Divider(),
                WrListRow(
                  title: tr('تخصيص غير مكتمل', 'Unreconciled allocation'),
                  trailing: WrAmountText(
                    amount: unknown.earning?.authoritativeAmount,
                    unavailableLabel: tr(
                      'المبلغ غير متاح',
                      'Amount unavailable',
                    ),
                  ),
                ),
                const Divider(),
                WrAmountText(
                  amount: usd.money,
                  unavailableLabel: tr('غير متاح', 'Unavailable'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomAction: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: WrNavigationItem(
              label: tr('اليوم', 'Today'),
              icon: Icons.today_outlined,
              selected: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: WrNavigationItem(
              label: tr('الطلبات', 'Jobs'),
              icon: Icons.work_outline,
              onTap: () {},
            ),
          ),
          Expanded(
            child: WrNavigationItem(
              label: tr('الجدول', 'Schedule'),
              icon: Icons.event_outlined,
              onTap: () {},
            ),
          ),
          Expanded(
            child: WrNavigationItem(
              label: tr('الأرباح', 'Earnings'),
              icon: Icons.account_balance_wallet_outlined,
              onTap: () {},
            ),
          ),
          Expanded(
            child: WrNavigationItem(
              label: tr('الحساب', 'Account'),
              icon: Icons.person_outline,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
