import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/extension_request_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the approved extension quote and supplied breakdown', (
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

    expect(find.text('المبلغ الإضافي المعتمد'), findsOneWidget);
    expect(find.text('القيمة الأساسية'), findsOneWidget);
    expect(find.text('هامش الادارة'), findsNothing);
    expect(find.text('4500.00 SYP'), findsOneWidget);
    expect(find.text('500.00 SYP'), findsNothing);
    expect(find.text('5000.00 SYP'), findsOneWidget);
    expect(find.text('صافي الربح'), findsNothing);
  });

  testWidgets('legacy response shows only the quote without inferred split', (
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

    expect(find.text('المبلغ الإضافي المعتمد'), findsOneWidget);
    expect(find.text('هامش الادارة'), findsNothing);
    expect(find.text('صافي الربح'), findsNothing);
    expect(find.text('القيمة الأساسية'), findsNothing);
  });

  testWidgets(
    'valid breakdown wraps without overflow at 2x text and narrow widths',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final width in <double>[320, 360, 430]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: ExtensionRequestAmountBreakdown(
                  baseAmount: 4500,
                  adminMargin: 500,
                  totalAmount: 5000,
                  currency: 'SYP',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'width $width');
        expect(find.text('المبلغ الإضافي المعتمد'), findsOneWidget);
        expect(find.text('القيمة الأساسية'), findsOneWidget);
        expect(find.text('هامش الادارة'), findsNothing);
      }
    },
  );
}
