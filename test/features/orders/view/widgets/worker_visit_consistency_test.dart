import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_mission_task_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/worker_order_overview_card.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/worker_order_requirements_card.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/worker_action_terms_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visit SOS requires accepted worker assignment as well as the time', () {
    WorkerBookingSessionModel session(String assignmentStatus) =>
        WorkerBookingSessionModel.fromJson({
          'date': '2026-11-12',
          'time': '09:00:00',
          'status': 'worker_assigned',
          'hours': 2,
          'workerAssignmentState': {'status': assignmentStatus},
        });
    final hourBefore = DateTime(2026, 11, 12, 8);
    expect(
      OrderLifecyclePolicy.canShowSessionSos(
        session('pending'),
        now: hourBefore,
      ),
      isFalse,
    );
    expect(
      OrderLifecyclePolicy.canShowSessionSos(
        session('accepted'),
        now: hourBefore,
      ),
      isTrue,
    );
    expect(
      OrderLifecyclePolicy.canShowSessionSos(
        session('withdrawn'),
        now: hourBefore,
      ),
      isFalse,
    );
  });

  test('SOS appears exactly one hour before a scheduled visit', () {
    expect(
      OrderLifecyclePolicy.canShowScheduledSos(
        date: '2026-11-12',
        time: '09:00:00',
        now: DateTime(2026, 11, 12, 7, 59),
      ),
      isFalse,
    );
    expect(
      OrderLifecyclePolicy.canShowScheduledSos(
        date: '2026-11-12',
        time: '09:00:00',
        now: DateTime(2026, 11, 12, 8),
      ),
      isTrue,
    );
    expect(
      OrderLifecyclePolicy.canShowScheduledSos(
        date: null,
        time: '09:00:00',
        now: DateTime(2026, 11, 12, 8),
      ),
      isFalse,
    );
  });

  test('backend cancellation penalty remains separate from booking fee', () {
    final order = FetchOrdersUsecaseModelDataItem.fromJson({
      'cancellationFee': 0,
      'workerCancellationPenaltyAmount': 1500,
    });
    expect(order.cancellationFee, 0);
    expect(order.workerCancellationPenaltyAmount, 1500);
    expect(order.toJson()['workerCancellationPenaltyAmount'], 1500);
  });

  test(
    'historic visits display the recorded room counts without V2 room requirements',
    () {
      final order = FetchOrdersUsecaseModelDataItem.fromJson({
        'status': 'worker_assigned',
        'propertyDetails': {'bedRooms': 2, 'bathrooms': 1, 'kitchens': 1},
      });
      final tasks = OrderMissionTaskMapper.build(order: order);
      expect(tasks.map((task) => task.label), contains('غرفة نوم × 2'));
      expect(tasks.map((task) => task.label), contains('حمام × 1'));
      expect(tasks.map((task) => task.label), contains('مطبخ × 1'));
    },
  );

  testWidgets('visit overview displays visit payout, not parent booking sum', (
    tester,
  ) async {
    final order = FetchOrdersUsecaseModelDataItem.fromJson({
      'status': 'worker_assigned',
      'workerAmount': 999999,
      'workerFinancials': {'netAmount': 999999},
      'scheduledDate': '2026-10-20',
      'scheduledTime': '09:00:00',
    });
    final visit = WorkerBookingSessionModel.fromJson({
      'id': 12,
      'sequence': 1,
      'date': '2026-11-12',
      'time': '13:00:00',
      'hours': 2,
      'status': 'worker_assigned',
      'workerAssignmentState': {'workerAmount': 1234, 'currency': 'SYP'},
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkerOrderOverviewCard(order: order, visit: visit),
        ),
      ),
    );
    expect(find.textContaining('1,234'), findsOneWidget);
    expect(find.textContaining('999,999'), findsNothing);
    expect(find.textContaining('2026'), findsWidgets);
  });

  testWidgets('requirements support seeded rooms and special previews', (
    tester,
  ) async {
    final order = FetchOrdersUsecaseModelDataItem.fromJson({
      'status': 'worker_assigned',
      'roomRequirements': [
        {'roomType': 'kitchen', 'roomSize': 'medium', 'count': 1},
      ],
      'specialServicesPreview': [
        {'name': 'تنظيف الأفران', 'quantity': 1},
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WorkerOrderRequirementsCard(order: order)),
      ),
    );
    expect(find.textContaining('مطبخ'), findsWidgets);
    expect(find.text('تنظيف الأفران'), findsOneWidget);
  });

  testWidgets(
    'acceptance terms require explicit unchecked-by-default consent',
    (tester) async {
      bool? result;
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await confirmWorkerActionTerms(
                    context,
                    cancelling: false,
                  );
                },
                child: const Text('افتح الشروط'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح الشروط'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'تأكيد قبول الطلب');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(result, isTrue);
    },
  );

  testWidgets(
    'cancellation terms never claim a fee is unavailable when the amount is absent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    confirmWorkerActionTerms(context, cancelling: true),
                child: const Text('شروط الإلغاء'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('شروط الإلغاء'));
      await tester.pumpAndSettle();
      expect(find.text('شروط إلغاء الزيارة'), findsOneWidget);
      expect(find.textContaining('غير متاحة حالياً'), findsNothing);
      expect(find.textContaining('24 ساعة'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'المتابعة إلى سبب الإلغاء'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('a server-supplied cancellation fee is labelled as configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmWorkerActionTerms(
                context,
                cancelling: true,
                cancellationPenaltyAmount: 250,
              ),
              child: const Text('عرض الشروط'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('عرض الشروط'));
    await tester.pumpAndSettle();
    expect(find.textContaining('250 ل.س'), findsOneWidget);
    expect(find.textContaining('خُصمت مسبقاً'), findsOneWidget);
  });
}
