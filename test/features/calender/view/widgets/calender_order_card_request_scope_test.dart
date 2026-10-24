import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dartz/dartz.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/calender/view/widgets/calender_order_card.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../support/finish_widget_cleanup.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{'worker_id': 99});
    await SharedPreferencesHelper.init();
  });
  tearDown(() async => getIt.reset());

  testWidgets('late booking A response never replaces visible booking B', (
    tester,
  ) async {
    final a = Completer<WorkerMultiDayBookingEnvelope>();
    final b = Completer<WorkerMultiDayBookingEnvelope>();
    final source = _ScheduleSource([a, b]);
    getIt.registerSingleton<WorkerSessionRemoteDataSource>(source);
    final bloc = _ordersBloc();
    await tester.pumpWidget(_host(bloc, _booking(101)));
    expect(source.ids, [101]);
    await tester.pumpWidget(_host(bloc, _booking(202)));
    expect(source.ids, [101, 202]);
    b.complete(_envelope(202, sequence: 2));
    await _pumpRead(tester);
    expect(find.text('الجلسة 2/2'), findsOneWidget);
    a.complete(_envelope(101, sequence: 1));
    await _pumpRead(tester);
    expect(find.text('الجلسة 2/2'), findsOneWidget);
    expect(find.text('الجلسة 1/2'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'new same-ID booking snapshot revokes earlier schedule response',
    (tester) async {
      final old = Completer<WorkerMultiDayBookingEnvelope>();
      final refreshed = Completer<WorkerMultiDayBookingEnvelope>();
      final source = _ScheduleSource([old, refreshed]);
      getIt.registerSingleton<WorkerSessionRemoteDataSource>(source);
      final bloc = _ordersBloc();
      await tester.pumpWidget(
        _host(bloc, _booking(303, status: 'worker_assigned')),
      );
      await tester.pumpWidget(
        _host(bloc, _booking(303, status: 'in_progress')),
      );
      expect(source.ids, [303, 303]);
      refreshed.complete(_envelope(303, sequence: 2));
      await _pumpRead(tester);
      old.complete(_envelope(303, sequence: 1));
      await _pumpRead(tester);
      expect(find.text('الجلسة 2/2'), findsOneWidget);
      expect(find.text('الجلسة 1/2'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await finishWidgetCleanup(tester, bloc.close());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('mismatched schedule parent fails closed', (tester) async {
    final response = Completer<WorkerMultiDayBookingEnvelope>();
    getIt.registerSingleton<WorkerSessionRemoteDataSource>(
      _ScheduleSource([response]),
    );
    final bloc = _ordersBloc();
    await tester.pumpWidget(_host(bloc, _booking(404)));
    response.complete(_envelope(405, sequence: 2));
    await _pumpRead(tester);
    expect(find.text('الجلسة 2/2'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('empty selected day does not display another day session', (
    tester,
  ) async {
    getIt.registerSingleton<WorkerSessionRemoteDataSource>(
      _ScheduleSource([
        Completer<WorkerMultiDayBookingEnvelope>()..complete(
          _scheduleEnvelope(
            411,
            sessions: [
              _sessionOn(1, DateTime(2026, 11, 3)),
              _sessionOn(2, DateTime(2026, 11, 4)),
            ],
            nextSessionSequence: 2,
          ),
        ),
      ]),
    );
    final bloc = _ordersBloc(selectedDate: '2026-11-02');
    await tester.pumpWidget(_host(bloc, _booking(411)));
    await _pumpRead(tester);

    expect(find.text('الجلسة 2/2'), findsNothing);
    expect(find.text('الجلسة 1/2'), findsNothing);
    expect(find.text('مدة الجلسة'), findsNothing);
    expect(find.text('Test venue 411'), findsOneWidget);
    expect(find.text('جدولة الحجز'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'selected-day match displays that day when next session differs',
    (tester) async {
      getIt.registerSingleton<WorkerSessionRemoteDataSource>(
        _ScheduleSource([
          Completer<WorkerMultiDayBookingEnvelope>()..complete(
            _scheduleEnvelope(
              412,
              sessions: [
                _sessionOn(1, DateTime(2026, 11, 2)),
                _sessionOn(2, DateTime(2026, 11, 3)),
              ],
              nextSessionSequence: 2,
            ),
          ),
        ]),
      );
      final bloc = _ordersBloc(selectedDate: '2026-11-02');
      await tester.pumpWidget(_host(bloc, _booking(412)));
      await _pumpRead(tester);

      expect(find.text('الجلسة 1/2'), findsOneWidget);
      expect(find.text('الجلسة 2/2'), findsNothing);
      expect(find.text('مدة الجلسة'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await finishWidgetCleanup(tester, bloc.close());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('legacy booking card remains when schedule has no sessions', (
    tester,
  ) async {
    getIt.registerSingleton<WorkerSessionRemoteDataSource>(
      _ScheduleSource([
        Completer<WorkerMultiDayBookingEnvelope>()..complete(
          _scheduleEnvelope(413, sessions: [], nextSessionSequence: null),
        ),
      ]),
    );
    final bloc = _ordersBloc(selectedDate: '2026-11-02');
    await tester.pumpWidget(_host(bloc, _booking(413)));
    await _pumpRead(tester);

    expect(find.text('الجلسة 1/2'), findsNothing);
    expect(find.text('مدة الجلسة'), findsNothing);
    expect(find.text('Test venue 413'), findsOneWidget);
    expect(find.text('جدولة الحجز'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'a booking switch immediately clears previously visible sessions',
    (tester) async {
      final first = Completer<WorkerMultiDayBookingEnvelope>();
      final pending = Completer<WorkerMultiDayBookingEnvelope>();
      final source = _ScheduleSource([first, pending]);
      getIt.registerSingleton<WorkerSessionRemoteDataSource>(source);
      final bloc = _ordersBloc();
      await tester.pumpWidget(_host(bloc, _booking(601)));
      first.complete(_envelope(601, sequence: 1));
      await _pumpRead(tester);
      expect(find.text('الجلسة 1/2'), findsOneWidget);

      await tester.pumpWidget(_host(bloc, _booking(602)));
      expect(source.ids, [601, 602]);
      expect(find.text('الجلسة 1/2'), findsNothing);

      pending.complete(_envelope(602, sequence: 2));
      await _pumpRead(tester);
      expect(find.text('الجلسة 2/2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await finishWidgetCleanup(tester, bloc.close());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('a 403 after refresh does not restore the prior session', (
    tester,
  ) async {
    final first = Completer<WorkerMultiDayBookingEnvelope>();
    final rejected = Completer<WorkerMultiDayBookingEnvelope>();
    final source = _ScheduleSource([first, rejected]);
    getIt.registerSingleton<WorkerSessionRemoteDataSource>(source);
    final bloc = _ordersBloc();
    await tester.pumpWidget(_host(bloc, _booking(701)));
    first.complete(_envelope(701, sequence: 1));
    await _pumpRead(tester);
    expect(find.text('الجلسة 1/2'), findsOneWidget);

    await tester.pumpWidget(_host(bloc, _booking(701, status: 'in_progress')));
    expect(find.text('الجلسة 1/2'), findsNothing);
    rejected.completeError(StateError('403 forbidden'));
    await _pumpRead(tester);
    expect(find.text('الجلسة 1/2'), findsNothing);
    expect(source.ids, [701, 701]);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a successful response after disposal cannot render sessions', (
    tester,
  ) async {
    final pending = Completer<WorkerMultiDayBookingEnvelope>();
    getIt.registerSingleton<WorkerSessionRemoteDataSource>(
      _ScheduleSource([pending]),
    );
    final bloc = _ordersBloc();
    await tester.pumpWidget(_host(bloc, _booking(801)));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(_envelope(801, sequence: 2));
    await _pumpRead(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('الجلسة 2/2'), findsNothing);
    await finishWidgetCleanup(tester, bloc.close());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'denied schedule and disposed cards cannot show private session',
    (tester) async {
      final denied = Completer<WorkerMultiDayBookingEnvelope>();
      getIt.registerSingleton<WorkerSessionRemoteDataSource>(
        _ScheduleSource([denied]),
      );
      final bloc = _ordersBloc();
      await tester.pumpWidget(_host(bloc, _booking(505)));
      await tester.pumpWidget(const SizedBox.shrink());
      denied.completeError(StateError('403 forbidden'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await finishWidgetCleanup(tester, bloc.close());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}

Future<void> _pumpRead(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

FetchOrdersUsecaseModelDataItem _booking(
  int id, {
  String status = 'worker_assigned',
}) => FetchOrdersUsecaseModelDataItem(
  id: id,
  status: status,
  propertyType: 'event_assistance',
  locationName: 'Test venue $id',
  scheduledDate: '2026-11-02',
  scheduledTime: '12:00',
);

WorkerMultiDayBookingEnvelope _envelope(
  int bookingId, {
  required int sequence,
}) => WorkerMultiDayBookingEnvelope(
  bookingId: bookingId,
  schedule: WorkerBookingScheduleModel(
    mode: 'multi_day',
    daysCount: 2,
    completedDaysCount: 0,
    cancelledDaysCount: 0,
    remainingDaysCount: 2,
    totalHours: 4,
    nextSession: _session(sequence),
    sessions: [_session(sequence)],
  ),
);

WorkerMultiDayBookingEnvelope _scheduleEnvelope(
  int bookingId, {
  required List<WorkerBookingSessionModel> sessions,
  required int? nextSessionSequence,
}) => WorkerMultiDayBookingEnvelope(
  bookingId: bookingId,
  schedule: WorkerBookingScheduleModel(
    mode: 'multi_day',
    daysCount: 2,
    completedDaysCount: 0,
    cancelledDaysCount: 0,
    remainingDaysCount: sessions.length,
    totalHours: sessions.length * 2,
    nextSession: nextSessionSequence == null
        ? null
        : sessions.firstWhere(
            (session) => session.sequence == nextSessionSequence,
          ),
    sessions: sessions,
  ),
);

WorkerBookingSessionModel _sessionOn(int sequence, DateTime date) =>
    WorkerBookingSessionModel(
      id: 2000 + sequence,
      sequence: sequence,
      date: date,
      time: '12:00',
      hours: 2,
      status: 'scheduled',
      isToday: false,
      isPast: false,
      canStartTravel: false,
      canArrive: false,
      canStartWork: false,
      canComplete: false,
      canExtend: false,
      canCancel: false,
    );

WorkerBookingSessionModel _session(int sequence) => WorkerBookingSessionModel(
  id: 1000 + sequence,
  sequence: sequence,
  date: DateTime(2026, 11, 2),
  time: '12:00',
  hours: 2,
  status: 'scheduled',
  isToday: false,
  isPast: false,
  canStartTravel: false,
  canArrive: false,
  canStartWork: false,
  canComplete: false,
  canExtend: false,
  canCancel: false,
);

Widget _host(OrdersBloc bloc, FetchOrdersUsecaseModelDataItem order) =>
    ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: BlocProvider<OrdersBloc>.value(
            value: bloc,
            child: SingleChildScrollView(
              child: CalenderOrderCard(date: order, index: 0),
            ),
          ),
        ),
      ),
    );

OrdersBloc _ordersBloc({String? selectedDate}) {
  final repo = _UnusedOrdersRepo();
  return _CalendarOrdersBloc(
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
    selectedDate,
  );
}

class _CalendarOrdersBloc extends OrdersBloc {
  _CalendarOrdersBloc(
    super.fetchOrdersUsecaseUseCase,
    super.fetchOrderDetailsUsecaseUseCase,
    super.acceptOrderUsecaseUseCase,
    super.startTravelUsecaseUseCase,
    super.completeOrderUsecaseUseCase,
    super.cancelOrderUseCase,
    super.fetchExtensionRequestsUsecasUseCase,
    super.acceptExtensionUsecaseUseCase,
    super.rejectExtensionUsecaseUseCase,
    super.updateAvailabilityUsecaseUseCase,
    super.rejectOrderUsecaseUseCase,
    super.arriveUseCase,
    super.postBookingLocationUseCase,
    super.fetchSecurityCodeUseCase,
    super.startWorkUseCase,
    this.selectedDate,
  );

  final String? selectedDate;

  @override
  FetchOrdersUsecaseParams get lastAppliedOrdersListFilter =>
      FetchOrdersUsecaseParams(page: 1, scheduledDate: selectedDate);
}

class _UnusedOrdersRepo implements OrdersRepo {
  @override
  DataResponse<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(
    FetchOrderDetailsUsecaseParams params,
  ) => Future.value(
    const Left<Failure, FetchOrderDetailsUsecaseModel>(
      ServerFailure(message: 'No live API in fixture', statusCode: 503),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScheduleSource extends WorkerSessionRemoteDataSource {
  _ScheduleSource(this.responses)
    : super(dioNetwork: DioNetwork(baseUrl: 'https://worker.example.test'));

  final List<Completer<WorkerMultiDayBookingEnvelope>> responses;
  final List<int> ids = [];

  @override
  Future<WorkerMultiDayBookingEnvelope> fetchBookingSchedule(int bookingId) {
    ids.add(bookingId);
    return responses[ids.length - 1].future;
  }
}
