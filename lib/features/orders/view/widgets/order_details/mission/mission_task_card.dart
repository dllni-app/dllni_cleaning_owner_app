import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../helpers/order_mission_task_mapper.dart';

class MissionTaskCard extends StatelessWidget {
  const MissionTaskCard({
    super.key,
    required this.tasks,
    required this.hintText,
    required this.isChecklistLocked,
    required this.allTasksChecked,
    required this.isChecked,
    required this.onChanged,
  });

  final List<MissionTaskItem> tasks;
  final String hintText;
  final bool isChecklistLocked;
  final bool allTasksChecked;
  final bool Function(MissionTaskItem task, int index) isChecked;
  final void Function(MissionTaskItem task, int index, bool value) onChanged;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(
            'قائمة المهام',
            color: const Color(0xff19B7C3),
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          AppText.bodySmall(
            hintText,
            color: isChecklistLocked
                ? const Color(0xffB45309)
                : const Color(0xff6B7280),
          ),
          const SizedBox(height: 12),
          ...tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            final checked = isChecklistLocked || isChecked(task, index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isChecklistLocked
                      ? const Color(0xffF1F5F9)
                      : const Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecklistLocked
                        ? const Color(0xffCBD5E1)
                        : const Color(0xffE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: isChecklistLocked
                          ? null
                          : (value) => onChanged(task, index, value ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Color(0xffCBD5E1)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            task.label,
                            fontWeight: FontWeight.w700,
                            color: isChecklistLocked
                                ? const Color(0xff64748B)
                                : null,
                          ),
                          if (task.detail != null)
                            AppText.bodySmall(
                              task.detail!,
                              color: const Color(0xff9CA3AF),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (!isChecklistLocked && !allTasksChecked) ...[
            const SizedBox(height: 2),
            AppText.bodySmall(
              'حدّد المهام التي أنجزتها قبل إرسال طلب الإنهاء',
              color: context.error,
            ),
          ],
        ],
      ),
    );
  }
}
