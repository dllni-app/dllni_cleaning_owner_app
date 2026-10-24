import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/design_system/design_system.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';

Widget fixture(Widget child, {bool arabic = true, double scale = 1}) {
  return MaterialApp(
    theme: WorkerV2Theme.light(),
    locale: Locale(arabic ? 'ar' : 'en'),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

/// Inspects the actual accessible nodes, including those created by EditableText.
List<SemanticsNode> semanticsNodes(WidgetTester tester) {
  // The test view attaches its semantics to the test binding's child owner.
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return nodes;
}

void main() {
  testWidgets('busy and disabled actions do not dispatch and expose state', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    var calls = 0;
    await tester.pumpWidget(
      fixture(
        Column(
          children: [
            WrActionButton(
              label: 'تحميل',
              busy: true,
              busyLabel: 'جارٍ تحميل البيانات',
              onPressed: () => calls++,
            ),
            WrActionButton(
              label: 'غير مسموح',
              disabledExplanation: 'انتظار المشرف',
            ),
            WrActionButton(label: 'إرسال', onPressed: () => calls++),
          ],
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('تحميل'), warnIfMissed: false);
    await tester.tap(find.text('غير مسموح'), warnIfMissed: false);
    expect(calls, 0);
    await tester.tap(find.text('إرسال'));
    expect(calls, 1);
    final nodes = semanticsNodes(tester);
    final busyNode = nodes.singleWhere((node) => node.label == 'تحميل');
    final disabledNode = nodes.singleWhere((node) => node.label == 'غير مسموح');
    expect(
      tester
          .widget<Semantics>(
            find
                .descendant(
                  of: find.byType(WrActionButton).first,
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .properties
          .enabled,
      false,
    );
    expect(busyNode.label, contains('تحميل'));
    expect(busyNode.value, contains('جارٍ تحميل البيانات'));
    expect(disabledNode.value, isNot(contains('جارٍ')));
    expect(disabledNode.hint, contains('انتظار المشرف'));
    semanticsHandle.dispose();
  });

  testWidgets(
    'icon and confirmation busy state identifies progress in Arabic',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(
        fixture(
          Column(
            children: [
              WrIconAction(
                icon: Icons.refresh,
                label: 'تحديث',
                busy: true,
                busyLabel: 'جارٍ التحديث',
                onPressed: () => calls++,
              ),
              WrIconAction(icon: Icons.close, label: 'مغلق'),
              WrConfirmDialog(
                title: 'تأكيد',
                message: 'هل تريد الإرسال؟',
                confirmLabel: 'نعم',
                cancelLabel: 'إلغاء',
                onConfirm: () => calls++,
                busy: true,
                busyLabel: 'جارٍ تأكيد العملية',
              ),
            ],
          ),
        ),
      );
      final nodes = semanticsNodes(tester);
      final iconBusy = nodes.singleWhere((node) => node.label == 'تحديث');
      final iconDisabled = nodes.singleWhere((node) => node.label == 'مغلق');
      final confirm = nodes.singleWhere((node) => node.label == 'نعم');
      expect(iconBusy.value, 'جارٍ التحديث');
      expect(iconDisabled.value, isEmpty);
      expect(confirm.value, 'جارٍ تأكيد العملية');
      await tester.tap(find.byType(IconButton).first, warnIfMissed: false);
      await tester.tap(find.text('نعم'), warnIfMissed: false);
      expect(calls, 0);
      semanticsHandle.dispose();
    },
  );

  for (final arabic in [true, false]) {
    testWidgets(
      'editable field labels belong to input semantics ${arabic ? 'RTL' : 'LTR'} at scale 2',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        final labels = arabic
            ? ['الاسم', 'الهاتف', 'الوقت', 'كلمة المرور']
            : ['Name', 'Phone', 'Time', 'Password'];
        await tester.pumpWidget(
          fixture(
            Column(
              children: [
                WrField(label: labels[0]),
                WrPhoneField(label: labels[1]),
                WrTimeField(label: labels[2]),
                WrPasswordField(
                  label: labels[3],
                  revealLabel: arabic ? 'إظهار' : 'Reveal',
                  hideLabel: arabic ? 'إخفاء' : 'Hide',
                ),
              ],
            ),
            arabic: arabic,
            scale: 2,
          ),
        );
        expect(find.byType(TextField), findsNWidgets(4));
        for (var i = 0; i < labels.length; i++) {
          final field = tester.widget<TextField>(find.byType(TextField).at(i));
          expect(field.decoration?.labelText, labels[i]);
          expect(
            field.decoration?.floatingLabelBehavior,
            FloatingLabelBehavior.always,
          );
          expect(field.decoration?.hintText, isNull);
          expect(
            semanticsNodes(tester).where(
              (node) =>
                  node.flagsCollection.isTextField &&
                  node.label.contains(labels[i]),
            ),
            hasLength(1),
          );
        }
        await tester.enterText(find.byType(TextField).last, 'hiddenSecret999');
        final passwordNode = semanticsNodes(tester).singleWhere(
          (node) =>
              node.flagsCollection.isTextField &&
              node.label.contains(labels.last),
        );
        expect(passwordNode.flagsCollection.isObscured, true);
        expect(passwordNode.value, isNot(contains('hiddenSecret999')));
        expect(tester.takeException(), isNull);
        semanticsHandle.dispose();
      },
    );
  }

  for (final arabic in [true, false]) {
    testWidgets(
      'panel subtitle is visible with or without title at scale 2 ${arabic ? 'RTL' : 'LTR'}',
      (tester) async {
        await tester.pumpWidget(
          fixture(
            const Column(
              children: [
                WrSectionPanel(
                  subtitle: 'Subtitle only',
                  child: Text('Body one'),
                ),
                WrSectionPanel(
                  title: 'Title',
                  subtitle: 'Title subtitle',
                  child: Text('Body two'),
                ),
              ],
            ),
            arabic: arabic,
            scale: 2,
          ),
        );
        expect(find.text('Subtitle only'), findsOneWidget);
        expect(find.text('Title subtitle'), findsOneWidget);
        expect(find.text('Body one'), findsOneWidget);
        expect(find.text('Body two'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('distinct null and exact zero money, with LTR digits in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      fixture(
        Column(
          children: [
            WrAmountText(
              amount: MoneyValue(decimal: '0.00', currency: 'SYP'),
              unavailableLabel: 'غير متاح',
            ),
            const WrAmountText(
              amount: null,
              unavailableLabel: 'المبلغ غير متاح',
            ),
          ],
        ),
      ),
    );
    expect(find.text('0.00 SYP'), findsOneWidget);
    expect(find.text('المبلغ غير متاح'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(
            find
                .ancestor(
                  of: find.text('0.00 SYP'),
                  matching: find.byType(Directionality),
                )
                .first,
          )
          .textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('phone and time stay LTR; password reveal and field error', (
    tester,
  ) async {
    await tester.pumpWidget(
      fixture(
        const Column(
          children: [
            WrPhoneField(label: 'رقم الهاتف', errorText: 'رقم غير صالح'),
            WrTimeField(label: 'الوقت'),
            WrPasswordField(
              label: 'كلمة المرور',
              revealLabel: 'إظهار',
              hideLabel: 'إخفاء',
            ),
          ],
        ),
      ),
    );
    final inputs = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(inputs.length, 3);
    expect(inputs[0].textDirection, TextDirection.ltr);
    expect(inputs[1].textDirection, TextDirection.ltr);
    expect(inputs[2].obscureText, true);
    expect(find.text('رقم غير صالح'), findsOneWidget);
    await tester.tap(find.byTooltip('إظهار'));
    await tester.pump();
    expect(
      tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
      false,
    );
    expect(find.byTooltip('إخفاء'), findsOneWidget);
  });

  testWidgets('retained refresh failure preserves content and retries', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      fixture(
        WrFeedbackPanel(
          kind: WrFeedbackKind.refreshError,
          title: 'تعذّر التحديث',
          retainedContent: const Text('المحتوى السابق'),
          retryLabel: 'إعادة المحاولة',
          onRetry: () => retries++,
        ),
      ),
    );
    expect(find.text('المحتوى السابق'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retries, 1);
    await tester.pumpWidget(
      fixture(
        const WrFeedbackPanel(
          kind: WrFeedbackKind.initialError,
          title: 'خطأ التحميل',
        ),
      ),
    );
    expect(find.text('المحتوى السابق'), findsNothing);
  });

  testWidgets('sheet accounts for viewInsets and blocks submit while busy', (
    tester,
  ) async {
    var submits = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: WorkerV2Theme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            viewInsets: EdgeInsets.only(bottom: 220),
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: WrSheetFrame(
                title: 'تأكيد',
                primaryLabel: 'إرسال',
                onPrimary: () => submits++,
                submitting: true,
                submittingLabel: 'جارٍ الإرسال',
                child: const Text('النص'),
              ),
            ),
          ),
        ),
      ),
    );
    final padding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(WrSheetFrame),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding.resolve(TextDirection.ltr).bottom, 220);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('إرسال'), warnIfMissed: false);
    expect(submits, 0);
  });

  for (final arabic in [true, false]) {
    for (final width in [320.0, 360.0, 430.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets(
          '${arabic ? 'RTL' : 'LTR'} width $width text scale $scale no overflow',
          (tester) async {
            tester.view.physicalSize = Size(width, 1100);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              fixture(
                Column(
                  children: [
                    const WrStatusBadge(
                      label: 'حالة طويلة وطويلة جداً بدون اقتطاع بيانات مهمة',
                      tone: WrStatusTone.warning,
                    ),
                    WrListRow(
                      title: arabic
                          ? 'تفاصيل الزيارة الطويلة التي يجب أن تظهر كاملة'
                          : 'Complete visit details with meaningful long content',
                      trailing: WrAmountText(
                        amount: MoneyValue(
                          decimal: '100000.00',
                          currency: 'SYP',
                        ),
                        unavailableLabel: 'Unavailable',
                      ),
                    ),
                    const WrEligibilityNotice(
                      title: 'بانتظار تأكيد العميل',
                      message: 'العمل متوقف حتى يتم تأكيد الطلب بشكل صريح',
                    ),
                    WrActionButton(
                      label: 'إجراء تشغيلي طويل يجب عرض كامل النص للمستخدم',
                      onPressed: () {},
                    ),
                  ],
                ),
                arabic: arabic,
                scale: scale,
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
