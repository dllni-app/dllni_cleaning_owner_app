import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class MissionWaitingCustomerCard extends StatelessWidget {
  const MissionWaitingCustomerCard({
    super.key,
    required this.visible,
    required this.completionMessage,
  });

  final bool visible;
  final String? completionMessage;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xff1E2A78),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText.bodyMedium(
                      'تم إرسال طلب إنهاء العمل إلى العميل. بانتظار التأكيد أو طلب إجراء آخر.',
                      color: const Color(0xff1E2A78),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
              if (completionMessage != null) ...[
                const SizedBox(height: 10),
                AppText.labelMedium(
                  'رسالتك للعميل:',
                  color: const Color(0xff1E2A78),
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 4),
                AppText.bodySmall(
                  completionMessage!,
                  color: const Color(0xff374151),
                  textAlign: TextAlign.start,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
