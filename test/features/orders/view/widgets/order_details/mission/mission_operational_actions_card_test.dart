import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_operational_details.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/mission/mission_operational_actions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders RTL operational decisions accessibly in dark mode with large text',
    (tester) async {
      tester.view.physicalSize = const Size(375, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E2A7B),
              brightness: Brightness.dark,
            ),
          ),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 1200),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: MissionOperationalActionsCard(
                    bookingId: 91,
                    loadScheduleChanges: () async => const [],
                    openTime: const CleaningOpenTimeDetails(
                      isOpenTime: true,
                      serverNow: '2026-09-10T10:00:00Z',
                      ceilingEndsAt: '2026-09-10T14:00:00Z',
                      endStatus: 'pending',
                      pendingExtension: CleaningOpenTimeExtensionDetails(
                        id: 7,
                        requestedMinutes: 30,
                        status: 'pending',
                      ),
                    ),
                    materialKit: const CleaningMaterialKitDetails(
                      status: 'ready',
                    ),
                    services: const [
                      CleaningSpecialServiceLine(
                        id: 12,
                        name: 'تنظيف كنب',
                        executionStatus: 'in_progress',
                        equipmentReservations: [
                          CleaningEquipmentReservationDetails(
                            id: 44,
                            name: 'جهاز الاستخراج',
                            status: 'acknowledged',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'إجراءات المهمة التشغيلية',
        ),
        findsOneWidget,
      );
      expect(find.text('طلب تمديد الوقت'), findsOneWidget);
      expect(find.text('طلب العميل إنهاء الخدمة'), findsOneWidget);
      expect(find.text('تأكيد الاستلام'), findsOneWidget);
      expect(find.text('تم التنفيذ'), findsOneWidget);
      expect(find.text('إرجاع جهاز الاستخراج'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final confirmationButton = find.widgetWithText(
        FilledButton,
        'تأكيد الاستلام',
      );
      expect(
        tester.getSize(confirmationButton).height,
        greaterThanOrEqualTo(48),
      );
      semantics.dispose();
    },
  );
}
