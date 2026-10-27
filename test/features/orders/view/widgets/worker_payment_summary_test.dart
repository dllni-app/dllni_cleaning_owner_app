import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/worker_payment_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => ScreenUtilPlusInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('shows only worker service share, travel and payable', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WorkerPaymentSummary(
          basePrice: 1450,
          bookingBasePrice: 2900,
          bookingServicePriceIncludingAdmin: 3625,
          bookingAdminMargin: 725,
          travelFee: 10,
          adminMargin: 725,
          addonsTotal: 200,
          totalPrice: 3700,
          useWorkerShare: true,
          serviceShareAmount: 1450,
          baseServiceShareAmount: 1250,
          specialServicesShareAmount: 200,
          workerAmount: 1460,
          plannedWorkerCount: 2,
          adminMarginPercentage: 25,
        ),
      ),
    );

    expect(find.text('حصتك من الخدمة'), findsOneWidget);
    expect(find.text('بدل المواصلات'), findsOneWidget);
    expect(find.text('مستحقك الحالي'), findsOneWidget);
    expect(find.text('1,450 ل.س'), findsOneWidget);
    expect(find.text('10 ل.س'), findsOneWidget);
    expect(find.text('1,460 ل.س'), findsOneWidget);
    expect(find.textContaining('هامش الإدارة'), findsNothing);
    expect(find.textContaining('عمال'), findsNothing);
    expect(find.textContaining('3,625'), findsNothing);
    expect(find.textContaining('725'), findsNothing);
    expect(find.textContaining('الخدمات الخاصة'), findsNothing);
    expect(find.textContaining('يعتمد'), findsNothing);
  });

  testWidgets(
    'never calculates missing worker amount or falls back to booking total',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const WorkerPaymentSummary(
            basePrice: 2900,
            travelFee: null,
            adminMargin: 725,
            addonsTotal: 0,
            totalPrice: 3625,
            useWorkerShare: true,
            workerAmount: null,
          ),
        ),
      );
      expect(find.text('قيد التحديد'), findsNWidgets(3));
      expect(find.textContaining('2,900'), findsNothing);
      expect(find.textContaining('3,625'), findsNothing);
    },
  );

  testWidgets(
    'final status uses server payable without attendance explanation',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const WorkerPaymentSummary(
            basePrice: null,
            travelFee: 10,
            adminMargin: 725,
            addonsTotal: null,
            totalPrice: null,
            serviceShareAmount: 2900,
            workerAmount: 2910,
            useWorkerShare: true,
            plannedWorkerCount: 2,
            actualWorkerCount: 1,
            isFinal: true,
          ),
        ),
      );
      expect(find.text('مستحقك النهائي'), findsOneWidget);
      expect(find.text('2,900 ل.س'), findsOneWidget);
      expect(find.text('2,910 ل.س'), findsOneWidget);
      expect(find.textContaining('الحضور'), findsNothing);
    },
  );
}
