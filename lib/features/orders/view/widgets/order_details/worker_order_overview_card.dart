import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_worker_order_status.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/worker_app_colors.dart';

/// Worker-scoped identity, earnings and next appointment. Reusable on the
/// booking detail and acceptance surfaces; never displays customer order total.
class WorkerOrderOverviewCard extends StatelessWidget {
  const WorkerOrderOverviewCard({super.key, required this.order, this.visit});

  final FetchOrdersUsecaseModelDataItem order;
  final WorkerBookingSessionModel? visit;

  @override
  Widget build(BuildContext context) {
    final isMultiWorker = (order.numberOfWorkers ?? 1) > 1;
    final individualHours =
        visit?.hours ??
        order.myAssignment?.totalHours ??
        order.estimatedHours ??
        order.totalHours ??
        order.bookingTotalHours;
    final earnings = visit == null
        ? order.workerPayableAmount
        : (visit!.workerAssignmentState?.workerAmount ??
              visit!.workerAssignmentState?.netAmount ??
              visit!.financial?.netAmount);
    final visitDate = visit?.date;
    final scheduledDate = visitDate == null
        ? order.scheduledDate
        : '${visitDate.year.toString().padLeft(4, '0')}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}';
    final scheduledTime = visit?.time ?? order.scheduledTime;
    final minutes = individualHours == null
        ? null
        : (individualHours * 60).round();
    final formattedHours = minutes == null
        ? 'قيد التحديد'
        : minutes < 60
        ? '$minutes دقيقة'
        : minutes % 60 == 0
        ? '${minutes ~/ 60} ساعة'
        : '${minutes ~/ 60} ساعة و${minutes % 60} دقيقة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WorkerAppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WorkerAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: WorkerAppColors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ملخص مهمتي',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isMultiWorker)
                const Text(
                  'ضمن فريق',
                  style: TextStyle(color: WorkerAppColors.brandPrimary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.effectiveWorkerStatusLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WorkerAppColors.brandPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OverviewValue(
                  label:
                      visit != null ||
                          !isMultiWorker ||
                          order.isWorkerDistributionFinal
                      ? 'مستحقاتك'
                      : 'مستحقك الحالي',
                  value: earnings?.formatMoney() ?? 'قيد التحديد',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewValue(
                  label: 'مدة العمل المتوقعة',
                  value: formattedHours,
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.event_outlined,
                size: 18,
                color: WorkerAppColors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${CleaningArabicTimeFormatter.formatScheduledDate(scheduledDate, emptyValue: 'الموعد غير محدد')} • ${CleaningArabicTimeFormatter.formatScheduledTime(scheduledTime, emptyValue: '—')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: WorkerAppColors.canvas,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: WorkerAppColors.brandPrimary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WorkerAppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
