import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/core/routes/app_router.dart';
import 'package:dllni_cleaninig_owner_app/core/notifications/cleaning_notification_order_loader_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/emergency_sos_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/screens/main_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/transaction_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';

class _OrdersBlocPlaceholder extends Fake implements OrdersBloc {}

void main() {
  test('explicit visit selection never substitutes an unrelated session', () {
    final schedule = WorkerBookingScheduleModel.fromJson({
      'mode': 'multi_day',
      'sessions': [
        {'id': 302},
        {'id': 303},
      ],
    });
    expect(schedule.canHonorExplicitSession(302), true);
    expect(schedule.canHonorExplicitSession(303), true);
    expect(schedule.canHonorExplicitSession(999), false);
    expect(schedule.canHonorExplicitSession(null), true);
    final legacyOnly = WorkerBookingScheduleModel.fromJson({
      'mode': 'single_day',
      'sessions': [
        {'id': 302},
      ],
    });
    expect(legacyOnly.canHonorExplicitSession(302), true);
    expect(legacyOnly.canHonorExplicitSession(999), false);
  });

  testWidgets('production notification accepts matching integer aliases', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(
                name: 'cleaning_booking_details',
                arguments: {
                  'bookingId': 202.0,
                  'booking_id': '202',
                  'sessionId': 302,
                  'session_id': '302',
                },
              ),
            );
            final page = (route! as MaterialPageRoute).builder(context);
            expect(page, isA<CleaningNotificationOrderLoaderScreen>());
            expect(
              (page as CleaningNotificationOrderLoaderScreen).bookingId,
              202,
            );
            expect(page.selectedSessionId, 302);
            // Inspect only: mounting this page would trigger a live API call.
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets(
    'production cleaning deep link rejects invalid and conflicting IDs',
    (tester) async {
      final invalidArguments = <Object?>[
        {'bookingId': 0},
        {'booking_id': -3},
        {'bookingId': 20.5},
        {'bookingId': 'not-an-id'},
        {'bookingId': 202, 'booking_id': 203},
        {'bookingId': 202, 'booking_id': null},
        {'bookingId': 202, 'session_id': 0},
        {'bookingId': 202, 'session_id': 'invalid'},
        {'bookingId': 202, 'session_id': 302, 'sessionId': 303},
        {},
      ];
      for (final arguments in invalidArguments) {
        final route = AppRouter.onGenerateRoute(
          RouteSettings(name: 'cleaning_booking_details', arguments: arguments),
        );
        expect(route, isNotNull);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(route!),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(
          find.text('Unable to open cleaning booking'),
          findsOneWidget,
          reason: '$arguments must not open a different booking',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  test(
    'real legacy order params preserve booking and explicitly selected visit',
    () {
      final args = OrderDetailsScreenParams(
        order: FetchOrdersUsecaseModelDataItem(id: 202),
        isNewOrder: false,
        bloc: _OrdersBlocPlaceholder(),
        index: 0,
        selectedSessionId: 302,
      );
      final resolved = AppRouter.previewWorkerRebuildIntent(
        RouteSettings(name: '/orderdetails', arguments: args),
        origin: RouteOrigin.notification,
      );
      expect(resolved.intent!.scope!.bookingId, '202');
      expect(resolved.intent!.scope!.sessionId, '302');
      expect(resolved.intent!.origin, RouteOrigin.notification);
      final unavailable = AppRouter.previewWorkerRebuildIntent(
        RouteSettings(
          name: '/orderdetails',
          arguments: OrderDetailsScreenParams(
            order: FetchOrdersUsecaseModelDataItem(id: 202),
            isNewOrder: false,
            bloc: _OrdersBlocPlaceholder(),
            index: 0,
            selectedSessionId: -2,
          ),
        ),
      );
      expect(unavailable.errorCode, 'target_invalid');
    },
  );

  test(
    'legacy dispute, SOS, and main tab typed params bridge without widgets',
    () {
      final dispute = AppRouter.previewWorkerRebuildIntent(
        RouteSettings(
          name: '/transactiondetails',
          arguments: TransactionDetailsScreenParam(
            id: 500,
            title: '#500',
            isOpen: true,
          ),
        ),
      );
      expect(dispute.intent!.entityId, '500');
      expect(dispute.intent!.destination, WorkerDestination.disputeThread);
      final sos = AppRouter.previewWorkerRebuildIntent(
        RouteSettings(
          name: '/emergencysos',
          arguments: EmergencySosScreenParams(bookingId: 202),
        ),
      );
      expect(sos.intent!.scope!.bookingId, '202');
      final tab = AppRouter.previewWorkerRebuildIntent(
        RouteSettings(
          name: '/main',
          arguments: MainScreenParam(
            returnedPageIndex: 2,
            ordersInitialStatus: 'assigned',
          ),
        ),
      );
      expect(tab.intent!.destination, WorkerDestination.jobs);
      expect(tab.intent!.jobsStatusFilter, 'assigned');
    },
  );

  test('cold/warm notification map and actual generated aliases resolve', () {
    final cold = AppRouter.previewWorkerRebuildIntent(
      const RouteSettings(
        name: 'cleaning_booking_details',
        arguments: {'booking_id': 202, 'session_id': 302, 'assignment_id': 402},
      ),
    );
    expect(cold.intent!.scope!.sessionId, '302');
    expect(cold.intent!.scope!.assignmentId, '402');
    for (final alias in ['/updateprofile', '/workerreviews', '/workingtime']) {
      final route = AppRouter.previewWorkerRebuildIntent(
        RouteSettings(name: alias),
      );
      expect(route.isAvailable, true, reason: alias);
    }
    final noBooking = AppRouter.previewWorkerRebuildIntent(
      const RouteSettings(
        name: 'cleaning_booking_details',
        arguments: {'session_id': 302},
      ),
    );
    expect(noBooking.isAvailable, false);
  });

  test(
    'present invalid and conflicting visit aliases never become legacy scope',
    () {
      final invalidValues = <Object?>[
        0,
        -1,
        '',
        '  ',
        false,
        <int>[302],
        null,
      ];
      for (final value in invalidValues) {
        final result = AppRouter.previewWorkerRebuildIntent(
          RouteSettings(
            name: 'cleaning_booking_details',
            arguments: {'booking_id': 202, 'session_id': value},
          ),
        );
        expect(result.errorCode, 'target_invalid', reason: '$value');
      }

      for (final args in <Map<String, Object?>>[
        {'booking_id': 202, 'bookingId': 203},
        {'booking_id': 202, 'session_id': 302, 'sessionId': 303},
        {
          'booking_id': 202,
          'session_id': 302,
          'assignment_id': 402,
          'assignmentId': 403,
        },
      ]) {
        expect(
          AppRouter.previewWorkerRebuildIntent(
            RouteSettings(name: '/orderdetails', arguments: args),
          ).errorCode,
          'target_invalid',
        );
      }

      final opaque = AppRouter.previewWorkerRebuildIntent(
        const RouteSettings(
          name: '/orderdetails',
          arguments: {
            'bookingId': 'booking:opaque',
            'sessionId': 'visit/opaque',
          },
        ),
      );
      expect(opaque.intent!.scope!.bookingId, 'booking:opaque');
      expect(opaque.intent!.scope!.sessionId, 'visit/opaque');

      final legacy = AppRouter.previewWorkerRebuildIntent(
        const RouteSettings(
          name: '/orderdetails',
          arguments: {'booking_id': 202},
        ),
      );
      expect(legacy.intent!.scope!.sessionId, isNull);
      expect(
        AppRouter.previewWorkerRebuildIntent(
          const RouteSettings(
            name: '/orderdetails',
            arguments: {'booking_id': 202, 'assignment_id': 402},
          ),
        ).intent!.scope!.assignmentId,
        '402',
      );
      expect(
        AppRouter.previewWorkerRebuildIntent(
          const RouteSettings(
            name: '/orderdetails',
            arguments: {'assignment_id': 402},
          ),
        ).errorCode,
        'target_invalid',
      );
    },
  );
}
