import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/extension_request_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows base price, administration margin, and total', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExtensionRequestAmountBreakdown(
            baseAmount: 4500,
            adminMargin: 500,
            totalAmount: 5000,
            currency: 'SYP',
          ),
        ),
      ),
    );

    expect(find.text('سعر التمديد'), findsOneWidget);
    expect(find.text('هامش الادارة'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('4500.00 SYP'), findsOneWidget);
    expect(find.text('500.00 SYP'), findsOneWidget);
    expect(find.text('5000.00 SYP'), findsOneWidget);
  });

  testWidgets('legacy response shows only the total', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExtensionRequestAmountBreakdown(
            baseAmount: null,
            adminMargin: null,
            totalAmount: 5000,
            currency: 'SYP',
          ),
        ),
      ),
    );

    expect(find.text('سعر التمديد'), findsNothing);
    expect(find.text('هامش الادارة'), findsNothing);
    expect(find.text('الإجمالي'), findsOneWidget);
  });
}
