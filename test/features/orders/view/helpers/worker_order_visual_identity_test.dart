import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/worker_order_visual_identity.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/worker_order_identity_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Worker order visual identity (read-only)', () {
    test('separates normal cleaning, hourly and occasion families', () {
      final cleaning = WorkerOrderVisualIdentity.fromOrder(
        FetchOrdersUsecaseModelDataItem(propertyType: 'apartment'),
      );
      final hourly = WorkerOrderVisualIdentity.fromOrder(
        FetchOrdersUsecaseModelDataItem(bookingKind: 'open_time'),
      );
      final occasion = WorkerOrderVisualIdentity.fromOrder(
        FetchOrdersUsecaseModelDataItem(propertyType: 'event_assistance'),
      );

      expect(cleaning.family, 'تنظيف');
      expect(hourly.family, 'عامل بالساعة');
      expect(hourly.title, 'عامل بالساعة');
      expect(occasion.family, 'مساعدة مناسبات');
      expect(cleaning.isSupervised, isFalse);
    });

    test('group flag depends only on existing bookingKind', () {
      final identity = WorkerOrderVisualIdentity.fromOrder(
        FetchOrdersUsecaseModelDataItem(
          bookingKind: 'supervised_team',
          propertyType: 'event_assistance',
        ),
      );
      expect(identity.isSupervised, isTrue);
      expect(identity.family, 'مساعدة مناسبات');
    });

    test('same-day label handles invalid or missing dates safely', () {
      WorkerOrderVisualIdentity identity(String? created, String? scheduled) =>
          WorkerOrderVisualIdentity.fromOrder(
            FetchOrdersUsecaseModelDataItem(
              createdAt: created,
              scheduledDate: scheduled,
            ),
          );

      expect(
        identity('2026-10-21T07:00:00', '2026-10-21').isSameDayRequest,
        isTrue,
      );
      expect(identity('2026-10-20', '2026-10-21').isSameDayRequest, isFalse);
      expect(identity('invalid', '2026-10-21').isSameDayRequest, isFalse);
      expect(identity(null, '2026-10-21').isSameDayRequest, isFalse);
    });
  });

  testWidgets('RTL badges wrap at narrow mobile width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final identity = WorkerOrderVisualIdentity.fromOrder(
      FetchOrdersUsecaseModelDataItem(
        bookingKind: 'supervised_team',
        propertyType: 'apartment',
        createdAt: '2026-10-21T08:15:00',
        scheduledDate: '2026-10-21',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(18),
              child: WorkerOrderIdentityChips(
                identity: identity,
                isPreferredForMe: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('تنظيف'), findsOneWidget);
    expect(find.text('فريق بإدارة مشرف'), findsOneWidget);
    expect(find.text('محدد لك'), findsOneWidget);
    expect(find.text('طلب ساخن'), findsOneWidget);
    expect(find.text('أنا في الطريق'), findsNothing);
    expect(find.text('مواد التنظيف'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
