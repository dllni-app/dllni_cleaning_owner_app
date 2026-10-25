import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dartz/dartz.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/worker_session_remote_data_source.dart';
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
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../support/finish_widget_cleanup.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{'worker_id': 99});
    await SharedPreferencesHelper.init();
  });

  testWidgets(
    'delayed scoped schedule success opens the selected session once',
    (WidgetTester tester) async {
      final delayed = Completer<WorkerMultiDayBookingEnvelope>();
      final source = _QueuedScheduleSource(
        <Future<WorkerMultiDayBookingEnvelope> Function()>[
          () => delayed.future,
        ],
      );
      _registerScreenDependencies(source);
      final bloc = _buildOrdersBloc();

      await tester.pumpWidget(_screen(bloc));
      expect(source.calls, 1);
      await tester.pump();
      expect(source.calls, 1);

      delayed.complete(_scheduleEnvelope());
      await tester.pumpAndSettle();
      expect(source.calls, 1);
      // Both the session header and the worker summary show the same visit.
      expect(find.text('الجلسة 1 من 1'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await _dispose(tester, bloc);
    },
  );

  testWidgets('403 schedule error waits for one explicit retry', (
    WidgetTester tester,
  ) async {
    final lateDetails =
        Completer<Either<Failure, FetchOrderDetailsUsecaseModel>>();
    final source = _QueuedScheduleSource(
      <Future<WorkerMultiDayBookingEnvelope> Function()>[
        () => Future<WorkerMultiDayBookingEnvelope>.error(
          StateError('403 forbidden'),
        ),
        () => Future<WorkerMultiDayBookingEnvelope>.error(
          StateError('403 forbidden'),
        ),
      ],
    );
    _registerScreenDependencies(source);
    final bloc = _buildOrdersBloc(
      repo: _UnusedOrdersRepo(orderDetailsResponse: () => lateDetails.future),
    );

    await tester.pumpWidget(_screen(bloc));
    await tester.pumpAndSettle();
    expect(source.calls, 1);
    expect(
      find.text('تعذر تحميل جلسات الطلب. أعد المحاولة قبل تنفيذ أي إجراء.'),
      findsOneWidget,
    );

    await tester.pump();
    expect(source.calls, 1);
    lateDetails.complete(
      Right<Failure, FetchOrderDetailsUsecaseModel>(
        FetchOrderDetailsUsecaseModel(
          data: FetchOrderDetailsUsecaseModelData(
            id: 44,
            status: 'in_progress',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(source.calls, 1);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(source.calls, 2);
    expect(
      find.text('تعذر تحميل جلسات الطلب. أعد المحاولة قبل تنفيذ أي إجراء.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _dispose(tester, bloc);
  });

  testWidgets(
    'realtime channel 403 does not revoke an authorized REST schedule',
    (WidgetTester tester) async {
      final delayed = Completer<WorkerMultiDayBookingEnvelope>();
      final source = _QueuedScheduleSource(
        <Future<WorkerMultiDayBookingEnvelope> Function()>[
          () => delayed.future,
          () async => _scheduleEnvelope(),
        ],
      );
      final bridge = _NoopPusherClientBridge();
      _registerScreenDependencies(source, pusherClientBridge: bridge);
      final bloc = _buildOrdersBloc();

      await tester.pumpWidget(_screen(bloc));
      // The initial request intentionally remains pending while the spinner
      // animates; drain listener setup without waiting for that request.
      await tester.pump();
      expect(source.calls, 1);
      expect(bridge.subscriptionErrorHandler, isNotNull);

      bridge.emitSubscriptionError(
        'private-cleaning-booking.44',
        const <String, dynamic>{'statusCode': 403},
      );
      bridge.emitSubscriptionError(
        'private-cleaning-booking.44',
        const <String, dynamic>{'statusCode': 403},
      );
      // Realtime auth errors trigger a REST recheck. The mock details source
      // deliberately does not complete, so a full pumpAndSettle would wait
      // forever for that unrelated request.
      await tester.pump(const Duration(milliseconds: 400));
      expect(source.calls, 1);

      delayed.complete(_scheduleEnvelope());
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(source.calls, 1);
      expect(find.text('الجلسة 1 من 1'), findsWidgets);
      expect(
        find.text('تعذر التحقق من صلاحية الوصول إلى هذا الطلب.'),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await _dispose(tester, bloc);
    },
  );
}

Future<void> _dispose(WidgetTester tester, OrdersBloc bloc) async {
  await finishWidgetCleanup(tester, bloc.close());
  await getIt.reset();
}

Widget _screen(OrdersBloc bloc) => MaterialApp(
  home: OrderDetailsScreen(
    params: OrderDetailsScreenParams(
      order: FetchOrdersUsecaseModelDataItem(
        id: 44,
        status: 'in_progress',
        bookingKind: 'multi_day',
      ),
      isNewOrder: false,
      bloc: bloc,
      index: -1,
      selectedSessionId: 501,
      sessionDetailsOnly: true,
    ),
  ),
);

WorkerMultiDayBookingEnvelope _scheduleEnvelope() =>
    WorkerMultiDayBookingEnvelope(
      bookingId: 44,
      schedule: const WorkerBookingScheduleModel(
        mode: 'single_day',
        daysCount: 1,
        completedDaysCount: 0,
        cancelledDaysCount: 0,
        remainingDaysCount: 1,
        totalHours: 1,
        sessions: <WorkerBookingSessionModel>[
          WorkerBookingSessionModel(
            id: 501,
            sequence: 1,
            hours: 1,
            status: 'scheduled',
            statusLabel: 'الجلسة 501',
            isToday: false,
            isPast: false,
            canStartTravel: false,
            canArrive: false,
            canStartWork: false,
            canComplete: false,
            canExtend: false,
            canCancel: false,
          ),
        ],
      ),
    );

void _registerScreenDependencies(
  _QueuedScheduleSource source, {
  PusherClientBridge? pusherClientBridge,
}) {
  getIt.registerSingleton<WorkerSessionRemoteDataSource>(source);
  getIt.registerSingleton<PusherManager>(
    PusherManager(
      clientBridge: pusherClientBridge ?? _NoopPusherClientBridge(),
    ),
  );
}

OrdersBloc _buildOrdersBloc({_UnusedOrdersRepo? repo}) {
  repo ??= _UnusedOrdersRepo();
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

class _UnusedOrdersRepo implements OrdersRepo {
  _UnusedOrdersRepo({this.orderDetailsResponse});

  final Future<Either<Failure, FetchOrderDetailsUsecaseModel>> Function()?
  orderDetailsResponse;

  @override
  DataResponse<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(
    FetchOrderDetailsUsecaseParams params,
  ) =>
      orderDetailsResponse?.call() ??
      Future.value(
        const Left<Failure, FetchOrderDetailsUsecaseModel>(
          ServerFailure(message: 'not configured', statusCode: 500),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QueuedScheduleSource extends WorkerSessionRemoteDataSource {
  _QueuedScheduleSource(this.responses)
    : super(dioNetwork: DioNetwork(baseUrl: 'https://worker.example.test'));

  final List<Future<WorkerMultiDayBookingEnvelope> Function()> responses;
  var calls = 0;

  @override
  Future<WorkerMultiDayBookingEnvelope> fetchBookingSchedule(int bookingId) {
    final index = calls++;
    return responses[index < responses.length ? index : responses.length - 1]();
  }
}

class _NoopPusherClientBridge implements PusherClientBridge {
  void Function(String message, dynamic error)? subscriptionErrorHandler;

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
  }) async {
    subscriptionErrorHandler = onSubscriptionError;
  }

  void emitSubscriptionError(String message, dynamic error) {
    subscriptionErrorHandler?.call(message, error);
  }

  @override
  Future<void> subscribe({required String channelName}) async {}

  @override
  Future<void> unsubscribe({required String channelName}) async {}
}
