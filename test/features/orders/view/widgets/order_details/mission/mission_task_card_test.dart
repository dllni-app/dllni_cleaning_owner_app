import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_mission_task_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/mission/mission_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'rooms are displayed as booking information without a checklist',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MissionTaskCard(
              tasks: [
                MissionTaskItem(label: 'غرفة النوم 1', detail: 'كبيرة'),
                MissionTaskItem(label: 'المطبخ 1', detail: 'صغيرة'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('الغرف والأعمال المطلوبة'), findsOneWidget);
      expect(find.text('غرفة النوم 1'), findsOneWidget);
      expect(find.text('صغيرة'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('قائمة المهام'), findsNothing);
    },
  );
}
