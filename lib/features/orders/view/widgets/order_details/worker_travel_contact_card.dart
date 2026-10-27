import 'package:flutter/material.dart';

import '../../../../../core/theme/worker_app_colors.dart';

/// Contact details belong to the on-the-way/map step, not the pre-travel offer.
/// For team work the authorized supervisor is the only point of contact.
class WorkerTravelContactCard extends StatelessWidget {
  const WorkerTravelContactCard({
    super.key,
    required this.isTeam,
    this.name,
    this.phone,
    this.onCall,
    this.onMessage,
  });

  final bool isTeam;
  final String? name;
  final String? phone;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final title = isTeam ? 'التواصل مع المشرف' : 'التواصل مع العميل';
    final displayName = name?.trim();
    final displayPhone = phone?.trim();
    final hasPhone = displayPhone != null && displayPhone.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WorkerAppColors.surface,
        border: Border.all(color: WorkerAppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_outlined,
                color: WorkerAppColors.brandPrimary,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: WorkerAppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayName?.isNotEmpty == true
                ? displayName!
                : isTeam
                ? 'لم يُحدّد المشرف لهذه الزيارة بعد'
                : 'اسم العميل غير متوفر',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            hasPhone
                ? displayPhone
                : 'رقم التواصل غير متوفر، يرجى تحديث الطلب.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WorkerAppColors.textSecondary,
            ),
          ),
          if (hasPhone) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_outlined, size: 19),
                    label: const Text('اتصال'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.sms_outlined, size: 19),
                    label: const Text('رسالة SMS'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
