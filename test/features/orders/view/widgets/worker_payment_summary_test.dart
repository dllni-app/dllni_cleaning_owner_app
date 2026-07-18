import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/worker_payment_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return ScreenUtilPlusInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows all five payment breakdown rows', (tester) async {
    await tester.pumpWidget(
      wrap(
        const WorkerPaymentSummary(
          basePrice: 1000,
          travelFee: 120,
          adminMargin: 100,
          addonsTotal: 0,
          totalPrice: 1300,
        ),
      ),
    );

    expect(find.text('قيمة الخدمة'), findsOneWidget);
    expect(find.text('رسوم التنقل'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('هامش الإدارة'), findsOneWidget);
    expect(find.text('صافي الربح'), findsOneWidget);
    // Fallback net = totalPrice - adminMargin = 1200
    expect(find.textContaining('1,200'), findsOneWidget);
  });

  testWidgets('uses workerAmount for net profit when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        const WorkerPaymentSummary(
          basePrice: 1000,
          travelFee: 120,
          adminMargin: 100,
          addonsTotal: 0,
          totalPrice: 1300,
          useWorkerShare: true,
          serviceShareAmount: 800,
          workerAmount: 900,
        ),
      ),
    );

    expect(find.text('صافي الربح'), findsOneWidget);
    expect(find.textContaining('900'), findsOneWidget);
    expect(find.textContaining('1,200'), findsNothing);
  });
}
