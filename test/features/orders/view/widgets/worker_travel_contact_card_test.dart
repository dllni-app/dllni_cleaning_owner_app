import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/worker_travel_contact_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(WorkerTravelContactCard card) => MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: card),
    ),
  );

  testWidgets('group travel contact uses supervisor only, not customer', (
    tester,
  ) async {
    var calls = 0;
    var messages = 0;
    await tester.pumpWidget(
      wrap(
        WorkerTravelContactCard(
          isTeam: true,
          name: 'مشرف الزيارة',
          phone: '+963944100003',
          onCall: () => calls++,
          onMessage: () => messages++,
        ),
      ),
    );
    expect(find.text('التواصل مع المشرف'), findsOneWidget);
    expect(find.text('مشرف الزيارة'), findsOneWidget);
    expect(find.text('+963944100003'), findsOneWidget);
    expect(find.text('التواصل مع العميل'), findsNothing);
    await tester.tap(find.text('اتصال'));
    await tester.tap(find.text('رسالة SMS'));
    expect(calls, 1);
    expect(messages, 1);
  });

  testWidgets('individual travel contact uses customer', (tester) async {
    await tester.pumpWidget(
      wrap(
        const WorkerTravelContactCard(
          isTeam: false,
          name: 'العميل التجريبي',
          phone: '0944000000',
        ),
      ),
    );
    expect(find.text('التواصل مع العميل'), findsOneWidget);
    expect(find.text('العميل التجريبي'), findsOneWidget);
    expect(find.text('التواصل مع المشرف'), findsNothing);
  });

  testWidgets('missing supervisor data gives an explicit message, no calls', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const WorkerTravelContactCard(isTeam: true)));
    expect(find.text('لم يُحدّد المشرف لهذه الزيارة بعد'), findsOneWidget);
    expect(
      find.text('رقم التواصل غير متوفر، يرجى تحديث الطلب.'),
      findsOneWidget,
    );
    expect(find.text('اتصال'), findsNothing);
  });
}
