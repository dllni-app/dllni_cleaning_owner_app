import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class CompletionMessageSheet {
  const CompletionMessageSheet._();

  static Future<String?> show(
    BuildContext context, {
    required String? initialMessage,
  }) async {
    final controller = TextEditingController(text: initialMessage ?? '');
    try {
      return await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.titleMedium(
                'إرسال طلب تأكيد الإنهاء',
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AppText.bodyMedium(
                'يمكنك كتابة ملاحظة للعميل قبل إرسال طلب تأكيد إنهاء الخدمة.',
                textAlign: TextAlign.center,
                color: const Color(0xff6B7280),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'مثال: تم إنهاء الخدمة بالكامل.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(controller.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff1DBCC8),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إرسال للعميل'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
