import 'package:dllni_cleaninig_owner_app/features/profile/view/helpers/worker_profile_completeness_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IncompleteSectionWarningIcon renders warning icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: IncompleteSectionWarningIcon())),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets(
    'IncompleteProfileWarningDialog renders missing sections and actions',
    (tester) async {
      var completeNowTapped = false;
      var laterTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncompleteProfileWarningDialog(
              missingSectionsAr: const ['موقع بدء المهمة', 'مناطق العمل'],
              onCompleteNow: () => completeNowTapped = true,
              onLater: () => laterTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('بيانات الحساب غير مكتملة'), findsOneWidget);
      expect(find.textContaining('• موقع بدء المهمة'), findsOneWidget);
      expect(find.textContaining('• مناطق العمل'), findsOneWidget);

      await tester.tap(find.text('لاحقًا'));
      await tester.pump();
      expect(laterTapped, isTrue);

      await tester.tap(find.text('استكمال الآن'));
      await tester.pump();
      expect(completeNowTapped, isTrue);
    },
  );
}
