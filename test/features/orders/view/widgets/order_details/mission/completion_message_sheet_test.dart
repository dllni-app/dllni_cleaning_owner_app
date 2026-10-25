import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_mission_task_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/mission/completion_message_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'partial room completion sends only explicitly selected indexes',
    (tester) async {
      CompletionSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await CompletionMessageSheet.show(
                      context,
                      initialMessage: null,
                      rooms: const [
                        MissionTaskItem(label: 'المطبخ'),
                        MissionTaskItem(label: 'غرفة النوم'),
                      ],
                    ),
                child: const Text('إنهاء'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('إنهاء'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'إرسال للعميل'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      await tester.tap(find.text('إرسال للعميل'));
      await tester.pumpAndSettle();
      expect(result?.finishedRoomIndexes, {0});
    },
  );
  testWidgets(
    'only selected services count as finished, with a scrollable modal',
    (tester) async {
      CompletionSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await CompletionMessageSheet.show(
                      context,
                      initialMessage: null,
                      services: const [
                        MissionTaskItem(label: 'تنظيف خاص'),
                        MissionTaskItem(label: 'تلميع غير منجز'),
                      ],
                    ),
                child: const Text('فتح'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsWidgets);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      await tester.ensureVisible(find.text('إرسال للعميل'));
      await tester.tap(find.text('إرسال للعميل'));
      await tester.pumpAndSettle();
      expect(result?.finishedServiceIndexes, {0});
      expect(result?.finishedRoomIndexes, isEmpty);
    },
  );
}
