import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/worker_detail_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('acceptance review sections keep task action accessible', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: WorkerDetailSection(
              title: 'جميع الجلسات',
              icon: Icons.schedule_outlined,
              children: [
                const Text('الجلسة الأولى'),
                TextButton(
                  onPressed: () => selected = true,
                  child: const Text('تحديد الجلسات التي يمكنني قبولها'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('تحديد الجلسات التي يمكنني قبولها'));
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('task section remains readable at narrow RTL width', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: WorkerDetailSection(
                title: 'المهام والخدمات المطلوبة لهذه الجلسة',
                children: [Text('تنظيف الصالة وغرفة الضيوف')],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('المهام والخدمات المطلوبة لهذه الجلسة'), findsOneWidget);
    expect(find.text('تنظيف الصالة وغرفة الضيوف'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
