import 'package:dllni_cleaninig_owner_app/core/theme/app_semantic_colors.dart';
import 'package:dllni_cleaninig_owner_app/core/theme/app_theme.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_button.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_state_view.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_status_chip.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_surface_card.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/phone_number_widget/my_custom_phone_field_widget.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_lifecycle_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextScaler textScaler = TextScaler.noScaling}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('نظام واجهة عامل التنظيف', () {
    testWidgets('يوفر توكنز الثيم والألوان الدلالية', (tester) async {
      late Color primary;
      late Color success;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              primary = Theme.of(context).colorScheme.primary;
              success = context.semanticColors.success;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(primary, AppTheme.navy);
      expect(success, const Color(0xFF087443));
    });

    testWidgets('الزر يحافظ على هدف لمس 48dp ويعطل أثناء التحميل', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AppButton(label: 'حفظ', isLoading: true, onPressed: null)),
      );

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.bySemanticsLabel('حفظ، جارٍ التنفيذ'), findsOneWidget);
    });

    testWidgets('تعرض حالة الخطأ إعادة المحاولة وتنفذها', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _host(
          AppStateView.error(message: 'تعذر الاتصال', onRetry: () => retries++),
        ),
      );

      expect(find.text('تعذر الاتصال'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      expect(retries, 1);
    });

    testWidgets('يبقى المحتوى قابلاً للعرض في RTL وتكبير النص 200%', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AppStateView.empty(
            message: 'لا توجد طلبات جديدة يمكن عرضها في الوقت الحالي',
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );

      expect(
        Directionality.of(tester.element(find.byType(AppStateView))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('لا توجد طلبات جديدة يمكن عرضها في الوقت الحالي'),
        findsOneWidget,
      );
    });

    testWidgets('الشارة تعلن الحالة بنص ورمز', (tester) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: AppStatusChip(
              label: 'قيد التنفيذ',
              tone: AppStatusTone.info,
              icon: Icons.schedule_rounded,
            ),
          ),
        ),
      );

      expect(find.text('قيد التنفيذ'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('قيد التنفيذ'), findsWidgets);
    });

    testWidgets('بطاقة السطح قابلة للضغط وموصوفة دلالياً', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: AppSurfaceCard(
              semanticLabel: 'بطاقة المحفظة',
              onTap: () => taps++,
              child: const Text('الرصيد الحالي'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('الرصيد الحالي'));
      expect(taps, 1);
      expect(find.bySemanticsLabel(RegExp('بطاقة المحفظة')), findsOneWidget);
    });

    testWidgets('مسار الطلب يعمل في عرض 360 وتكبير 200%', (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(
          const SingleChildScrollView(
            child: OrderLifecycleProgress(currentStep: 2),
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );

      expect(find.text('الطلب'), findsOneWidget);
      expect(find.text('المهمة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('حقل الهاتف لا يفيض عند تكبير النص 200%', (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          Padding(
            padding: const EdgeInsets.all(16),
            child: MyCustomIntlField(
              controller: controller,
              initialCountryCode: 'SY',
              decoration: const InputDecoration(hintText: '9XX XXX XXX'),
            ),
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      expect(find.text('+963'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
