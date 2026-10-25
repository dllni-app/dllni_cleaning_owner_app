import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import '../../../helpers/order_mission_task_mapper.dart';

class CompletionSelection {
  const CompletionSelection(
    this.message,
    this.finishedRoomIndexes,
    this.finishedServiceIndexes,
  );

  final String message;
  final Set<int> finishedRoomIndexes;
  final Set<int> finishedServiceIndexes;
}

class CompletionMessageSheet {
  const CompletionMessageSheet._();

  static Future<CompletionSelection?> show(
    BuildContext context, {
    required String? initialMessage,
    List<MissionTaskItem> rooms = const [],
    List<MissionTaskItem> services = const [],
  }) async {
    final controller = TextEditingController(text: initialMessage ?? '');
    final selected = <int>{};
    final selectedServices = <int>{};
    try {
      return await showModalBottomSheet<CompletionSelection>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, updateSelection) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
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
                  if (rooms.isNotEmpty) ...[
                    const Text(
                      'اختر الغرف التي أُنجزت فعلياً. اترك الغرف غير المنجزة دون تحديد.',
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 8),
                    ...List<Widget>.generate(
                      rooms.length,
                      (index) => CheckboxListTile(
                        dense: true,
                        value: selected.contains(index),
                        title: Text(rooms[index].label),
                        subtitle: rooms[index].detail == null
                            ? null
                            : Text(rooms[index].detail!),
                        onChanged: (checked) => updateSelection(() {
                          if (checked == true) {
                            selected.add(index);
                          } else {
                            selected.remove(index);
                          }
                        }),
                      ),
                    ),
                    if (selected.isEmpty)
                      const Text(
                        'حدد غرفة منجزة واحدة على الأقل، أو ألغِ الإنهاء وتواصل مع الدعم.',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                    const SizedBox(height: 10),
                  ],
                  if (services.isNotEmpty) ...[
                    const Text(
                      'حدد الخدمات المنجزة فعلياً فقط. يمكنك ذكر الخدمات غير المنجزة في الملاحظة.',
                    ),
                    const SizedBox(height: 8),
                    ...List<Widget>.generate(
                      services.length,
                      (index) => CheckboxListTile(
                        dense: true,
                        value: selectedServices.contains(index),
                        title: Text(services[index].label),
                        subtitle: services[index].detail == null
                            ? null
                            : Text(services[index].detail!),
                        onChanged: (checked) => updateSelection(() {
                          if (checked == true) {
                            selectedServices.add(index);
                          } else {
                            selectedServices.remove(index);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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
                          onPressed: rooms.isNotEmpty && selected.isEmpty
                              ? null
                              : () => Navigator.of(ctx).pop(
                                  CompletionSelection(
                                    controller.text,
                                    Set<int>.of(selected),
                                    Set<int>.of(selectedServices),
                                  ),
                                ),
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
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
