import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../helpers/order_mission_task_mapper.dart';

/// Read-only scope of work received from the booking; no worker checklist.
class MissionTaskCard extends StatelessWidget {
  const MissionTaskCard({super.key, required this.tasks});

  final List<MissionTaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffECEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.titleMedium(
            tasks.every((task) => task.isReadOnlyInfo)
                ? 'تفاصيل المساعدة المطلوبة'
                : 'الغرف والأعمال المطلوبة',
            color: const Color(0xff19B7C3),
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 10),
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(task.label, fontWeight: FontWeight.w700),
                    if (task.detail != null &&
                        task.detail!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AppText.bodySmall(
                        task.detail!,
                        color: const Color(0xff64748B),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
