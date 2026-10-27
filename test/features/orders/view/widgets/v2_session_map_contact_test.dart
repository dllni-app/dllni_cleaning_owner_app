import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/multi_day_order_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('en'));

  testWidgets('V2 team travel shows supervisor and text-address map fallback', (
    tester,
  ) async {
    final order = fetchOrdersUsecaseModelDataItemFromJson({
      'id': 75,
      'status': 'worker_assigned',
      'bookingNumber': 'CLN-V2-VISIT-ASSIGNED',
      'bookingKind': 'standard',
      'numberOfWorkers': 2,
      'locationName': 'حلب - الحمدانية - شارع القدس',
      'supervisorContact': {'name': 'مشرف الفريق', 'phone': '+963944100003'},
      'customer': {'name': 'العميل', 'phone': '+963944100009'},
    });
    final schedule = WorkerBookingScheduleModel(
      mode: 'single_day',
      daysCount: 1,
      completedDaysCount: 0,
      cancelledDaysCount: 0,
      remainingDaysCount: 1,
      totalHours: 2,
      sessions: [
        WorkerBookingSessionModel(
          id: 41,
          sequence: 1,
          status: 'worker_assigned',
          date: DateTime(2026, 10, 28),
          time: '13:00',
          hours: 2,
          isToday: false,
          isPast: false,
          canStartTravel: false,
          canArrive: true,
          canStartWork: false,
          canComplete: false,
          canExtend: false,
          canCancel: false,
          workerAssignmentState: const WorkerSessionAssignmentModel(
            status: 'accepted',
            startedTravelAt: '2026-10-28T12:00:00+03:00',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(360, 690),
        builder: (context, _) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: MultiDayOrderDetailsBody(
                order: order,
                initialSchedule: schedule,
                initialSelectedSessionId: 41,
                sessionDetailsOnly: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('التواصل مع المشرف'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('مشرف الفريق'), findsOneWidget);
    expect(find.text('+963944100003'), findsOneWidget);
    expect(find.text('التواصل مع العميل'), findsNothing);
    expect(find.text('+963944100009'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('البحث عن العنوان في الخرائط'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('البحث عن العنوان في الخرائط'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
