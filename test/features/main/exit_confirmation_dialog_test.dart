import 'package:dllni_cleaninig_owner_app/core/widgets/exit_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Arabic exit prompt stays open until the worker chooses to stay',
    (tester) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  confirmed = await showExitConfirmationDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('الخروج من التطبيق'), findsOneWidget);
      expect(
        find.text('هل أنت متأكد من رغبتك في الخروج من التطبيق؟'),
        findsOneWidget,
      );
      final dialog = tester.element(find.byType(AlertDialog));
      expect(Directionality.of(dialog), TextDirection.rtl);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(confirmed, isNull);

      await tester.tap(find.text('البقاء'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(confirmed, isFalse);
    },
  );

  testWidgets('worker explicitly confirms exiting from the root prompt', (
    tester,
  ) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                confirmed = await showExitConfirmationDialog(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
