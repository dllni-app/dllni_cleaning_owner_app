import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/worker_order_overview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows worker payout and assignment status, not booking total', (
    tester,
  ) async {
    final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
      'bookingNumber': 'CLN-TEST',
      'status': 'pending',
      'worker_order_status': 'accepted_waiting_for_order_start',
      'bookingTotalPrice': 50000,
      'numberOfWorkers': 3,
      'required_workers_count': 3,
      'accepted_workers_count': 1,
      'totalHours': 9,
      'scheduledDate': '2026-10-26',
      'scheduledTime': '09:00',
      'myAssignment': <String, dynamic>{
        'workerAmount': 750,
        'serviceShareAmount': 700,
        'travelFee': 50,
        'totalHours': 3,
      },
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: WorkerOrderOverviewCard(order: order)),
        ),
      ),
    );

    expect(find.text('ملخص مهمتي'), findsOneWidget);
    expect(find.text('ضمن فريق'), findsOneWidget);
    expect(find.textContaining('750'), findsOneWidget);
    expect(find.textContaining('50,000'), findsNothing);
    expect(find.text('3 ساعة'), findsOneWidget);
    expect(find.text('9 ساعة'), findsNothing);
  });

  testWidgets('does not display fake zero or full total without worker offer', (
    tester,
  ) async {
    final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
      'status': 'pending',
      'numberOfWorkers': 2,
      'totalPrice': 12345,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WorkerOrderOverviewCard(order: order)),
      ),
    );

    expect(find.text('قيد التحديد'), findsWidgets);
    expect(find.textContaining('12,345'), findsNothing);
  });
}
