import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_extension_requests_usecas_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/reject_extension_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/repository/orders_repo.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/arrive_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/cancel_order_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/complete_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_security_code_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/post_booking_location_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_travel_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_work_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/update_availability_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_global_prompt_coordinator.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/finish_widget_cleanup.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const currentWorkerId = 99;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'worker_id': currentWorkerId,
      'user': jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{'id': currentWorkerId},
      }),
    });
    await SharedPreferencesHelper.init();
  });

  group('CleaningWorkerGlobalPromptCoordinator', () {
    testWidgets(
      'real root modal keeps realtime and resume work pending until close',
      (WidgetTester tester) async {
        await getIt.reset();
        final bloc = _buildCoordinatorOrdersBloc();
        getIt.registerSingleton<OrdersBloc>(bloc);
        final navigatorKey = GlobalKey<NavigatorState>();
        var handled = false;
        final coordinator =
            CleaningWorkerGlobalPromptCoordinator(
                navigatorKey: navigatorKey,
                pusherManager: _buildNoopPusherManager(),
                pendingRequestsLoader: () async =>
                    const <WorkerPendingExtensionRequest>[
                      WorkerPendingExtensionRequest(
                        warningId: 881,
                        bookingId: 44,
                        requestedMinutes: 30,
                        baseAmount: 100,
                        adminMargin: 0,
                        totalAmount: 100,
                        additionalAmount: 100,
                        currency: 'SYP',
                      ),
                      WorkerPendingExtensionRequest(
                        warningId: 882,
                        bookingId: 45,
                        requestedMinutes: 15,
                        baseAmount: 50,
                        adminMargin: 0,
                        totalAmount: 50,
                        additionalAmount: 50,
                        currency: 'SYP',
                      ),
                    ],
              )
              ..markStartedForTest()
              ..markAuthBypassForTest();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: SizedBox.expand()),
          ),
        );
        final eventHandling = coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 881,
            'cleaningBookingId': 44,
            'requestedMinutes': 30,
            'customerName': 'Customer',
            'baseAmount': 100,
            'adminMargin': 0,
            'totalAmount': 100,
            'additionalAmount': 100,
            'currency': 'SYP',
            'paymentMethod': 'cash',
          },
        )..then((_) => handled = true);
        await tester.pumpAndSettle();

        expect(find.text('طلب تمديد مدة العمل'), findsOneWidget);
        expect(handled, isFalse);
        final secondWarningHandling = coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 882,
            'cleaningBookingId': 45,
            'requestedMinutes': 15,
            'customerName': 'Customer 882',
            'baseAmount': 50,
            'adminMargin': 0,
            'totalAmount': 50,
            'additionalAmount': 50,
            'currency': 'SYP',
            'paymentMethod': 'cash',
          },
        );
        await tester.pumpAndSettle();
        expect(find.text('طلب تمديد مدة العمل'), findsOneWidget);
        expect(find.textContaining('15 دقيقة إضافية'), findsNothing);
        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 881,
            'cleaningBookingId': 44,
            'requestedMinutes': 30,
            'customerName': 'Customer',
            'baseAmount': 100,
            'adminMargin': 0,
            'totalAmount': 100,
            'additionalAmount': 100,
            'currency': 'SYP',
            'paymentMethod': 'cash',
          },
        );
        await coordinator.pollPendingExtensionPrompts();
        expect(find.text('طلب تمديد مدة العمل'), findsOneWidget);
        expect(handled, isFalse);

        await tester.tap(find.text('رفض الطلب'));
        await tester.pumpAndSettle();
        await eventHandling;
        expect(handled, isTrue);
        expect(find.text('طلب تمديد مدة العمل'), findsNothing);
        await secondWarningHandling;
        final resumedPoll = coordinator.pollPendingExtensionPrompts();
        await tester.pumpAndSettle();
        expect(find.textContaining('15 دقيقة إضافية'), findsOneWidget);
        expect(find.text('طلب تمديد مدة العمل'), findsOneWidget);
        await tester.tap(find.text('رفض الطلب'));
        await tester.pumpAndSettle();
        await resumedPoll;

        await tester.pumpWidget(const SizedBox.shrink());
        await finishWidgetCleanup(tester, coordinator.stop());
        await getIt.reset();
      },
    );
    testWidgets(
      'pending poll carries authoritative quote and keeps incomplete consent disabled',
      (WidgetTester tester) async {
        for (final request in <WorkerPendingExtensionRequest>[
          const WorkerPendingExtensionRequest(
            warningId: 891,
            bookingId: 49,
            requestedMinutes: 25,
            baseAmount: 100,
            adminMargin: 10,
            totalAmount: 110,
            additionalAmount: 110,
            currency: 'SYP',
          ),
          const WorkerPendingExtensionRequest(
            warningId: 892,
            bookingId: 50,
            requestedMinutes: 25,
            totalAmount: 110,
            additionalAmount: 110,
            currency: 'SYP',
          ),
        ]) {
          await getIt.reset();
          final bloc = _buildCoordinatorOrdersBloc();
          getIt.registerSingleton<OrdersBloc>(bloc);
          final navigatorKey = GlobalKey<NavigatorState>();
          final coordinator =
              CleaningWorkerGlobalPromptCoordinator(
                  navigatorKey: navigatorKey,
                  pusherManager: _buildNoopPusherManager(),
                  pendingRequestsLoader: () async =>
                      <WorkerPendingExtensionRequest>[request],
                )
                ..markStartedForTest()
                ..markAuthBypassForTest();
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigatorKey,
              home: const Scaffold(body: SizedBox.expand()),
            ),
          );

          final polling = coordinator.pollPendingExtensionPrompts();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('extension_total_quote')),
            findsOneWidget,
          );
          expect(find.text('المبلغ الإضافي المعتمد'), findsOneWidget);
          expect(find.text('110.00 SYP'), findsOneWidget);
          if (request.warningId == 891) {
            final accept = tester.widget<FilledButton>(
              find.widgetWithText(FilledButton, 'قبول الطلب'),
            );
            expect(accept.onPressed, isNotNull);
          } else {
            final accept = tester.widget<FilledButton>(
              find.widgetWithText(FilledButton, 'قبول الطلب'),
            );
            expect(accept.onPressed, isNull);
          }

          await tester.tap(find.text('رفض الطلب'));
          await tester.pumpAndSettle();
          await polling;
          await tester.pumpWidget(const SizedBox.shrink());
          await finishWidgetCleanup(tester, coordinator.stop());
          await getIt.reset();
        }
      },
    );
    test(
      'ServiceExtensionRequested opens extension prompt only once per warning id',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        const payload = <String, dynamic>{
          'warningId': 100,
          'cleaningBookingId': 42,
          'requestedMinutes': 30,
        };

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          payload,
        );
        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          payload,
        );

        expect(shown.length, 1);
        expect(shown.first.warningId, 100);
      },
    );

    test(
      'ServiceExtensionRequested ignores prompts targeted to another worker',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 201,
            'cleaningBookingId': 54,
            'workerId': currentWorkerId + 1,
            'requestedMinutes': 30,
          },
        );

        expect(shown, isEmpty);
      },
    );

    test(
      'an open extension prompt remains reserved until its presenter closes',
      () async {
        final presenterCompleted = Completer<bool>();
        var presentationCount = 0;
        final coordinator =
            CleaningWorkerGlobalPromptCoordinator(
                navigatorKey: GlobalKey<NavigatorState>(),
                pusherManager: _buildNoopPusherManager(),
                pendingRequestsLoader: () async =>
                    const <WorkerPendingExtensionRequest>[
                      WorkerPendingExtensionRequest(
                        warningId: 808,
                        bookingId: 18,
                        requestedMinutes: 30,
                      ),
                    ],
                extensionPromptPresenter: (_) {
                  presentationCount++;
                  return presenterCompleted.future;
                },
              )
              ..markStartedForTest()
              ..markAuthBypassForTest();

        final eventHandling = coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 808,
            'cleaningBookingId': 18,
            'requestedMinutes': 30,
          },
        );
        await Future<void>.delayed(Duration.zero);

        final duplicateEvent = coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 808,
            'cleaningBookingId': 18,
            'requestedMinutes': 30,
          },
        );
        final resumePoll = coordinator.pollPendingExtensionPrompts();
        await Future<void>.delayed(Duration.zero);

        expect(presentationCount, 1);
        presenterCompleted.complete(true);
        await Future.wait(<Future<void>>[
          eventHandling,
          duplicateEvent,
          resumePoll,
        ]);

        expect(presentationCount, 1);
      },
    );

    test('ServiceExtensionRequested unwraps nested data.warningId', () async {
      final shown = <WorkerExtensionPromptData>[];
      final coordinator = CleaningWorkerGlobalPromptCoordinator(
        navigatorKey: GlobalKey<NavigatorState>(),
        pusherManager: _buildNoopPusherManager(),
        extensionPromptPresenter: (prompt) async {
          shown.add(prompt);
          return true;
        },
      )..markStartedForTest();

      await coordinator.handleRealtimeEventForTest(
        'service_extension_requested',
        const <String, dynamic>{
          'data': <String, dynamic>{
            'warningId': 202,
            'cleaningBookingId': 55,
            'additionalMinutes': 15,
          },
        },
      );

      expect(shown.length, 1);
      expect(shown.first.warningId, 202);
      expect(shown.first.bookingId, 55);
      expect(shown.first.requestedMinutes, 15);
    });

    test(
      'ServiceExtensionRequested resolves additionalMinutes alias',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 101,
            'cleaningBookingId': 43,
            'additionalMinutes': 60,
          },
        );

        expect(shown.length, 1);
        expect(shown.first.requestedMinutes, 60);
      },
    );

    test(
      'ServiceExtensionRequested forwards the authoritative breakdown',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 303,
            'cleaningBookingId': 88,
            'requestedMinutes': 30,
            'baseAmount': '4500',
            'adminMargin': 500,
            'totalAmount': '5000.00',
            'additionalAmount': 5000,
            'currency': 'SYP',
          },
        );

        expect(shown.single.baseAmount, 4500);
        expect(shown.single.adminMargin, 500);
        expect(shown.single.totalAmount, 5000);
        expect(shown.single.additionalAmount, 5000);
        expect(shown.single.currency, 'SYP');
      },
    );

    test('CompletionDecisionMade approved shows success alert once', () async {
      final alerts = <WorkerDecisionAlertData>[];
      final coordinator = CleaningWorkerGlobalPromptCoordinator(
        navigatorKey: GlobalKey<NavigatorState>(),
        pusherManager: _buildNoopPusherManager(),
        decisionAlertPresenter: (prompt) async {
          alerts.add(prompt);
          return true;
        },
      )..markStartedForTest();

      const payload = <String, dynamic>{
        'cleaningBookingId': 7,
        'decision': 'approved',
        'version': 1,
      };

      await coordinator.handleRealtimeEventForTest(
        CleaningRealtimeContract.completionDecisionMade,
        payload,
      );
      await coordinator.handleRealtimeEventForTest(
        CleaningRealtimeContract.completionDecisionMade,
        payload,
      );

      expect(alerts.length, 1);
      expect(alerts.first.isApproved, isTrue);
      expect(alerts.first.title, 'تم تأكيد إنهاء العمل');
      expect(alerts.first.navigateToMainOnOk, isTrue);
    });

    test('CompletionDecisionMade rejected shows failure alert', () async {
      final alerts = <WorkerDecisionAlertData>[];
      final coordinator = CleaningWorkerGlobalPromptCoordinator(
        navigatorKey: GlobalKey<NavigatorState>(),
        pusherManager: _buildNoopPusherManager(),
        decisionAlertPresenter: (prompt) async {
          alerts.add(prompt);
          return true;
        },
      )..markStartedForTest();

      await coordinator.handleRealtimeEventForTest(
        CleaningRealtimeContract.completionDecisionMade,
        const <String, dynamic>{
          'cleaningBookingId': 8,
          'decision': 'rejected',
          'version': 3,
        },
      );

      expect(alerts.length, 1);
      expect(alerts.first.isApproved, isFalse);
      expect(alerts.first.message, contains('إعادة إرسال طلب الإنهاء'));
      expect(alerts.first.navigateToMainOnOk, isFalse);
    });

    test(
      'CompletionDecisionMade extension_requested triggers pending-extension fallback',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          pendingRequestsLoader: () async =>
              const <WorkerPendingExtensionRequest>[
                WorkerPendingExtensionRequest(
                  warningId: 501,
                  bookingId: 22,
                  requestedMinutes: 45,
                ),
              ],
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.completionDecisionMade,
          const <String, dynamic>{
            'cleaningBookingId': 22,
            'decision': 'extension_requested',
            'version': 4,
          },
        );

        expect(shown.length, 1);
        expect(shown.first.warningId, 501);
        expect(shown.first.requestedMinutes, 45);
      },
    );

    test('pollPendingExtensionPrompts opens first pending warning', () async {
      final shown = <WorkerExtensionPromptData>[];
      final coordinator =
          CleaningWorkerGlobalPromptCoordinator(
              navigatorKey: GlobalKey<NavigatorState>(),
              pusherManager: _buildNoopPusherManager(),
              pendingRequestsLoader: () async =>
                  const <WorkerPendingExtensionRequest>[
                    WorkerPendingExtensionRequest(
                      warningId: 777,
                      bookingId: 88,
                      requestedMinutes: 30,
                    ),
                  ],
              extensionPromptPresenter: (prompt) async {
                shown.add(prompt);
                return true;
              },
            )
            ..markStartedForTest()
            ..markAuthBypassForTest();

      await coordinator.pollPendingExtensionPrompts();

      expect(shown.length, 1);
      expect(shown.first.warningId, 777);
    });

    test(
      'pollPendingExtensionPrompts does not auto-open pending order accept prompt',
      () async {
        final shown = <WorkerPendingOrderPromptData>[];
        final coordinator =
            CleaningWorkerGlobalPromptCoordinator(
                navigatorKey: GlobalKey<NavigatorState>(),
                pusherManager: _buildNoopPusherManager(),
                pendingOrdersLoader: () async =>
                    <FetchOrdersUsecaseModelDataItem>[
                      FetchOrdersUsecaseModelDataItem(
                        id: 321,
                        status: CleaningBookingStatus.pending,
                        preferredWorkerId: currentWorkerId,
                      ),
                    ],
                pendingOrderPromptPresenter: (prompt) async {
                  shown.add(prompt);
                  return true;
                },
              )
              ..markStartedForTest()
              ..markAuthBypassForTest();

        await coordinator.pollPendingExtensionPrompts();

        expect(shown, isEmpty);
      },
    );

    test(
      'pollPendingExtensionPrompts still opens extension prompt when pending orders also exist',
      () async {
        final pendingShown = <WorkerPendingOrderPromptData>[];
        final extensionShown = <WorkerExtensionPromptData>[];
        final coordinator =
            CleaningWorkerGlobalPromptCoordinator(
                navigatorKey: GlobalKey<NavigatorState>(),
                pusherManager: _buildNoopPusherManager(),
                pendingOrdersLoader: () async =>
                    <FetchOrdersUsecaseModelDataItem>[
                      FetchOrdersUsecaseModelDataItem(
                        id: 654,
                        status: CleaningBookingStatus.pending,
                      ),
                    ],
                pendingOrderPromptPresenter: (prompt) async {
                  pendingShown.add(prompt);
                  return true;
                },
                pendingRequestsLoader: () async =>
                    const <WorkerPendingExtensionRequest>[
                      WorkerPendingExtensionRequest(
                        warningId: 7777,
                        bookingId: 654,
                        requestedMinutes: 30,
                      ),
                    ],
                extensionPromptPresenter: (prompt) async {
                  extensionShown.add(prompt);
                  return true;
                },
              )
              ..markStartedForTest()
              ..markAuthBypassForTest();

        await coordinator.pollPendingExtensionPrompts();

        expect(pendingShown, isEmpty);
        expect(extensionShown.length, 1);
        expect(extensionShown.first.warningId, 7777);
      },
    );

    test(
      'pollPendingExtensionPrompts ignores pending orders across repeated polls',
      () async {
        var presentedCount = 0;
        final coordinator =
            CleaningWorkerGlobalPromptCoordinator(
                navigatorKey: GlobalKey<NavigatorState>(),
                pusherManager: _buildNoopPusherManager(),
                pendingOrdersLoader: () async =>
                    <FetchOrdersUsecaseModelDataItem>[
                      FetchOrdersUsecaseModelDataItem(
                        id: 900,
                        status: CleaningBookingStatus.pending,
                      ),
                    ],
                pendingOrderPromptPresenter: (_) async {
                  presentedCount++;
                  return true;
                },
              )
              ..markStartedForTest()
              ..markAuthBypassForTest();

        await coordinator.pollPendingExtensionPrompts();
        await coordinator.pollPendingExtensionPrompts();

        expect(presentedCount, 0);
      },
    );

    test(
      'pollPendingOrderPrompts opens first pending dedicated order',
      () async {
        final shown = <WorkerPendingOrderPromptData>[];
        final coordinator =
            CleaningWorkerGlobalPromptCoordinator(
                navigatorKey: GlobalKey<NavigatorState>(),
                pusherManager: _buildNoopPusherManager(),
                pendingOrdersLoader: () async =>
                    <FetchOrdersUsecaseModelDataItem>[
                      FetchOrdersUsecaseModelDataItem(
                        id: 321,
                        status: CleaningBookingStatus.pending,
                        preferredWorkerId: currentWorkerId,
                      ),
                    ],
                pendingOrderPromptPresenter: (prompt) async {
                  shown.add(prompt);
                  return true;
                },
              )
              ..markStartedForTest()
              ..markAuthBypassForTest();

        await coordinator.pollPendingOrderPrompts();

        expect(shown.length, 1);
        expect(shown.first.order.id, 321);
      },
    );

    test('findTimeExtensionRequestedBookingIds filters by status', () {
      final ids =
          CleaningWorkerGlobalPromptCoordinator.findTimeExtensionRequestedBookingIds(
            <FetchOrdersUsecaseModelDataItem>[
              FetchOrdersUsecaseModelDataItem(
                id: 1,
                status: CleaningBookingStatus.timeExtensionRequested,
              ),
              FetchOrdersUsecaseModelDataItem(
                id: 2,
                status: CleaningBookingStatus.inProgress,
              ),
            ],
          );
      expect(ids, [1]);
    });

    test(
      'extension_requested then ServiceExtensionRequested does not duplicate same warning',
      () async {
        final shown = <WorkerExtensionPromptData>[];
        final coordinator = CleaningWorkerGlobalPromptCoordinator(
          navigatorKey: GlobalKey<NavigatorState>(),
          pusherManager: _buildNoopPusherManager(),
          pendingRequestsLoader: () async =>
              const <WorkerPendingExtensionRequest>[
                WorkerPendingExtensionRequest(
                  warningId: 909,
                  bookingId: 33,
                  requestedMinutes: 20,
                ),
              ],
          extensionPromptPresenter: (prompt) async {
            shown.add(prompt);
            return true;
          },
        )..markStartedForTest();

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.completionDecisionMade,
          const <String, dynamic>{
            'cleaningBookingId': 33,
            'decision': 'extension_requested',
            'version': 5,
          },
        );

        await coordinator.handleRealtimeEventForTest(
          CleaningRealtimeContract.serviceExtensionRequested,
          const <String, dynamic>{
            'warningId': 909,
            'cleaningBookingId': 33,
            'requestedMinutes': 20,
          },
        );

        expect(shown.length, 1);
      },
    );
  });
}

PusherManager _buildNoopPusherManager() {
  return PusherManager(clientBridge: _NoopPusherClientBridge(), authDio: Dio());
}

OrdersBloc _buildCoordinatorOrdersBloc() {
  final repo = _CoordinatorOrdersRepo();
  return OrdersBloc(
    FetchOrdersUsecaseUseCase(orders: repo),
    FetchOrderDetailsUsecaseUseCase(orders: repo),
    AcceptOrderUsecaseUseCase(orders: repo),
    StartTravelUsecaseUseCase(orders: repo),
    CompleteOrderUsecaseUseCase(orders: repo),
    CancelOrderUseCase(orders: repo),
    FetchExtensionRequestsUsecasUseCase(orders: repo),
    AcceptExtensionUsecaseUseCase(orders: repo),
    RejectExtensionUsecaseUseCase(orders: repo),
    UpdateAvailabilityUsecaseUseCase(orders: repo),
    RejectOrderUsecaseUseCase(orders: repo),
    ArriveUseCase(orders: repo),
    PostBookingLocationUseCase(orders: repo),
    FetchSecurityCodeUseCase(orders: repo),
    StartWorkUseCase(orders: repo),
  );
}

class _CoordinatorOrdersRepo implements OrdersRepo {
  @override
  DataResponse<RejectExtensionUsecaseModel> rejectExtensionUsecase(
    RejectExtensionUsecaseParams params,
  ) async => Right<Failure, RejectExtensionUsecaseModel>(
    RejectExtensionUsecaseModel(
      data: RejectExtensionUsecaseModelData(id: params.id),
    ),
  );

  @override
  DataResponse<FetchExtensionRequestsUsecasModel> fetchExtensionRequestsUsecas(
    FetchExtensionRequestsUsecasParams params,
  ) async => const Left<Failure, FetchExtensionRequestsUsecasModel>(
    ServerFailure(message: 'not configured', statusCode: 500),
  );

  @override
  DataResponse<FetchOrdersUsecaseModel> fetchOrdersUsecase(
    FetchOrdersUsecaseParams params,
  ) async => const Left<Failure, FetchOrdersUsecaseModel>(
    ServerFailure(message: 'not configured', statusCode: 500),
  );

  @override
  DataResponse<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(
    FetchOrderDetailsUsecaseParams params,
  ) async => const Left<Failure, FetchOrderDetailsUsecaseModel>(
    ServerFailure(message: 'not configured', statusCode: 500),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopPusherClientBridge implements PusherClientBridge {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> init({
    required String apiKey,
    required String cluster,
    required bool useTls,
    required Future<Map<String, dynamic>> Function(
      String channelName,
      String socketId,
      dynamic options,
    )
    onAuthorizer,
    required void Function(String message, dynamic error) onSubscriptionError,
    required void Function(String message, int? code, dynamic error) onError,
    required void Function(String channelName, dynamic data)
    onSubscriptionSucceeded,
    required void Function(String currentState, String previousState)
    onConnectionStateChange,
    required void Function(PusherEvent event) onEvent,
  }) async {}

  @override
  Future<void> subscribe({required String channelName}) async {}

  @override
  Future<void> unsubscribe({required String channelName}) async {}
}
