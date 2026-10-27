import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/estate_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(FetchOrdersUsecaseModelDataItem order) => ScreenUtilPlusInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(child: EstateInfoCard(order: order)),
        ),
      ),
    ),
  );

  testWidgets(
    'accepted team member sees the exact address supplied by backend',
    (tester) async {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'status': 'pending',
        'numberOfWorkers': 2,
        'myAssignment': <String, dynamic>{'status': 'accepted'},
        'neighborhoodName': 'الحمدانية',
        'address': <String, dynamic>{
          'fullAddress': 'حلب - الحمدانية - شارع القدس - بناء 12 - طابق 3',
        },
      });
      await tester.pumpWidget(wrap(order));
      expect(
        find.text('حلب - الحمدانية - شارع القدس - بناء 12 - طابق 3'),
        findsOneWidget,
      );
    },
  );

  testWidgets('unaccepted offer masks street and only shows neighborhood', (
    tester,
  ) async {
    final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
      'status': 'pending',
      'neighborhoodName': 'الحمدانية',
      'address': <String, dynamic>{
        'fullAddress': 'حلب - الحمدانية - شارع القدس - بناء 12',
      },
    });
    await tester.pumpWidget(wrap(order));
    expect(find.text('الحمدانية'), findsWidgets);
    expect(find.textContaining('شارع القدس'), findsNothing);
  });

  testWidgets('does not show cleaning mode as a separate property field', (
    tester,
  ) async {
    final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
      'status': 'worker_assigned',
      'propertyType': 'apartment',
      'propertyDetails': <String, dynamic>{
        'cleaningMode': 'deep',
        'cleaningModeLabel': 'تعزيل',
      },
    });
    await tester.pumpWidget(wrap(order));
    expect(find.text('نوع التنظيف'), findsNothing);
    expect(find.text('نوع العقار'), findsOneWidget);
  });
}
