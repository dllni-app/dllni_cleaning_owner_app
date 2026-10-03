import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_operational_details.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_open_time_presentation.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/mission/mission_operational_details_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('renders materials as read-only operational quantities', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const MissionMaterialsInfoCard(
          materials: <CleaningBookingMaterialLine>[
            CleaningBookingMaterialLine(
              name: 'منظف الأرضيات',
              quantity: 1.5,
              unitLabel: 'لتر',
            ),
          ],
        ),
      ),
    );

    expect(find.text('مواد التنظيف المطلوبة'), findsOneWidget);
    expect(find.text('منظف الأرضيات'), findsOneWidget);
    expect(find.text('الكمية: 1.5 لتر'), findsOneWidget);
    expect(find.textContaining('السعر'), findsNothing);
  });

  testWidgets('renders special-service operational equipment and notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const MissionSpecialServicesInfoCard(
          services: <CleaningSpecialServiceLine>[
            CleaningSpecialServiceLine(
              name: 'تنظيف السجاد',
              quantity: 2,
              pricingUnitLabel: 'قطعة',
              dirtinessLabel: 'شديد',
              equipment: <CleaningSpecialServiceEquipment>[
                CleaningSpecialServiceEquipment(name: 'آلة السجاد'),
              ],
              notes: 'تنظيف الحواف',
            ),
          ],
        ),
      ),
    );

    expect(find.text('الخدمات الخاصة'), findsOneWidget);
    expect(find.text('الكمية: 2 قطعة'), findsOneWidget);
    expect(find.text('مستوى الاتساخ: شديد'), findsOneWidget);
    expect(find.text('المعدات: آلة السجاد'), findsOneWidget);
    expect(find.text('ملاحظات: تنظيف الحواف'), findsOneWidget);
  });

  testWidgets('shows finalized Open-Time duration without a client price', (
    tester,
  ) async {
    const openTime = CleaningOpenTimeDetails(
      isOpenTime: true,
      workStartedAt: '2026-09-06T10:00:00Z',
      workFinishedAt: '2026-09-06T10:45:00Z',
      actualDurationMinutes: 44,
      billableDurationMinutes: 60,
      finalAmount: 120,
      isFinalized: true,
    );
    final presentation = OrderOpenTimePresentation.resolve(
      openTime: openTime,
      now: DateTime.utc(2026, 9, 6, 12),
    );

    await tester.pumpWidget(
      buildSubject(
        MissionOpenTimeInfoCard(openTime: openTime, presentation: presentation),
      ),
    );

    expect(find.text('طلب وقت مفتوح'), findsOneWidget);
    expect(find.text('المدة الفعلية للعمل'), findsOneWidget);
    expect(find.text('00:44:00'), findsOneWidget);
    expect(find.text('المدة القابلة للفوترة'), findsOneWidget);
    expect(find.textContaining('120'), findsNothing);
  });
}
