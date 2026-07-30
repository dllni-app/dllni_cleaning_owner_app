import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/worker_payment_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return ScreenUtilPlusInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('shows gross total before margin and net profit after margin', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WorkerPaymentSummary(
          basePrice: 120000,
          travelFee: 14000,
          adminMargin: 12000,
          addonsTotal: 0,
          totalPrice: 146000,
        ),
      ),
    );

    expect(find.text('قيمة الخدمة'), findsOneWidget);
    expect(find.text('رسوم التنقل'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('هامش الإدارة'), findsOneWidget);
    expect(find.text('صافي الربح'), findsOneWidget);
    expect(find.textContaining('134,000'), findsOneWidget);
    expect(find.textContaining('122,000'), findsOneWidget);
    expect(find.textContaining('146,000'), findsNothing);

    final totalY = tester.getTopLeft(find.text('الإجمالي')).dy;
    final marginY = tester.getTopLeft(find.text('هامش الإدارة')).dy;
    expect(totalY, lessThan(marginY));
  });

  testWidgets('calculates net profit before using legacy workerAmount', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WorkerPaymentSummary(
          basePrice: 1000,
          travelFee: 120,
          adminMargin: 100,
          addonsTotal: 0,
          totalPrice: 1120,
          useWorkerShare: true,
          serviceShareAmount: 800,
          workerAmount: 9000,
        ),
      ),
    );

    expect(find.text('صافي الربح'), findsOneWidget);
    expect(find.textContaining('820'), findsOneWidget);
    expect(find.textContaining('9,000'), findsNothing);
  });

  testWidgets(
    'falls back to workerAmount when pricing components are missing',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const WorkerPaymentSummary(
            basePrice: null,
            travelFee: null,
            adminMargin: null,
            addonsTotal: null,
            totalPrice: null,
            workerAmount: 900,
          ),
        ),
      );

      expect(find.text('صافي الربح'), findsOneWidget);
      expect(find.textContaining('900'), findsOneWidget);
      expect(find.textContaining('1,200'), findsNothing);
    },
  );
}
