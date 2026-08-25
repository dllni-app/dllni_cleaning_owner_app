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

  testWidgets('does not show the full booking price when worker share is pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const WorkerPaymentSummary(
          basePrice: 2000,
          travelFee: 101,
          adminMargin: 0,
          addonsTotal: 0,
          totalPrice: 2101,
          useWorkerShare: true,
          serviceShareAmount: null,
          workerAmount: 0,
        ),
      ),
    );

    expect(find.textContaining('2,000'), findsNothing);
    expect(find.textContaining('2,101'), findsNothing);
    expect(find.textContaining('101'), findsWidgets);
  });
}
