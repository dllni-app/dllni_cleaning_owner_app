import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class WaitingCustomerConfirmationSheet {
  const WaitingCustomerConfirmationSheet._();

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRefresh,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_outlined,
              size: 66,
              color: Color(0xff21B8C5),
            ),
            const SizedBox(height: 12),
            AppText.titleMedium(
              'تم إرسال طلب التأكيد',
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            AppText.bodyMedium(
              'تم إرسال طلب إنهاء الخدمة إلى العميل. سيتم تحديث حالة الطلب عند قبول العميل أو طلب إجراء آخر.',
              textAlign: TextAlign.center,
              color: const Color(0xff6B7280),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onRefresh();
                    },
                    child: const Text('تحديث الحالة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff1E2A78),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: AppText.labelLarge('تم', color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
