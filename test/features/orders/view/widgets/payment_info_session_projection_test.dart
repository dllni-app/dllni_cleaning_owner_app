import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/payment_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'worker card uses persisted V2 session projection instead of stale offer',
    (tester) async {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'numberOfWorkers': 2,
        'totalPrice': 3645,
        'workerFinancials': <String, dynamic>{
          'serviceShareAmount': 1450,
          'baseServiceShareAmount': 1300,
          'specialServicesShareAmount': 150,
          'materialsShareAmount': 25,
          'travelFee': 10,
          'adminMarginAmount': 362.5,
          'plannedWorkerCount': 2,
          'isFinal': false,
          'workerAmount': 1460,
        },
        'myAssignment': <String, dynamic>{
          'serviceShareAmount': 1665,
          'travelFee': 10,
          'adminMarginAmount': 416,
          'workerAmount': 1460,
        },
      });
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(360, 690),
          builder: (_, __) => MaterialApp(
            home: Scaffold(body: PaymentInfoCard(order: order)),
          ),
        ),
      );
      expect(find.text('حصتك من قيمة الخدمة'), findsOneWidget);
      expect(find.text('حصتك من الخدمات الخاصة'), findsOneWidget);
      expect(find.text('مواد التنظيف'), findsNothing);
      expect(find.text('25 ل.س'), findsNothing);
      expect(find.textContaining('1,300'), findsWidgets);
      expect(find.textContaining('150'), findsWidgets);
      expect(find.textContaining('1,460'), findsWidgets);
      expect(find.textContaining('362.5'), findsWidgets);
      expect(find.text('مستحقك الحالي'), findsOneWidget);
      expect(find.text('إجمالي مستحق العامل'), findsNothing);
      expect(find.textContaining('1,665'), findsNothing);
      expect(find.textContaining('416'), findsNothing);
      expect(find.textContaining('3,645'), findsNothing);
    },
  );

  testWidgets('financial card fits a narrow screen with large Arabic text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
      'numberOfWorkers': 3,
      'workerFinancials': <String, dynamic>{
        'serviceShareAmount': 1350.5,
        'baseServiceShareAmount': 1300,
        'specialServicesShareAmount': 50.5,
        'travelFee': 20,
        'adminMarginAmount': 337.63,
        'workerAmount': 1370.5,
        'plannedWorkerCount': 3,
        'isFinal': false,
      },
    });
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(child: PaymentInfoCard(order: order)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('حصتك من قيمة الخدمة'), findsOneWidget);
    expect(find.text('حصتك من الخدمات الخاصة'), findsOneWidget);
    expect(find.text('مستحقك الحالي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
