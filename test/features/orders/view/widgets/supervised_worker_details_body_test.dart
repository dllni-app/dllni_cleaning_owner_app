import 'dart:async';

import 'package:common_package/helpers/dio_network.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/arrive_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/start_travel_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/supervised_worker_booking.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_inventory.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/orders_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/arrive_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_travel_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/supervised_worker_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeOrdersRemoteDataSource source;

  setUp(() async {
    await getIt.reset();
    source = _FakeOrdersRemoteDataSource();
    getIt.registerSingleton<OrdersRemoteDataSource>(source);
  });

  tearDown(() async => getIt.reset());

  testWidgets('exposes only server-authorized personal attendance actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: SupervisedWorkerDetailsBody(bookingId: 41, onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('بدء التنقل'), findsOneWidget);
    expect(find.text('تأكيد الوصول'), findsNothing);
    expect(
      find.text(
        'سجّل حضورك الشخصي من هنا. بدء تنفيذ العمل والاستلام من مسؤولية المشرف.',
      ),
      findsOneWidget,
    );
    expect(find.text('بدء العمل'), findsNothing);
  });

  testWidgets(
    'attendance write refreshes server state and prevents duplicate taps',
    (tester) async {
      final writeGate = Completer<StartTravelUsecaseModel>();
      source.startTravelResult = writeGate.future;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: SupervisedWorkerDetailsBody(bookingId: 41, onBack: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('بدء التنقل'));
      await tester.pump();
      await tester.tap(find.text('بدء التنقل'));
      await tester.pump();
      expect(source.startTravelCalls, 1);

      source.booking = source.booking.copyWithAttendance(
        startedTravelAt: '2026-10-26T08:00:00Z',
        canStartTravel: false,
        canArrive: true,
      );
      writeGate.complete(
        StartTravelUsecaseModel(
          data: StartTravelUsecaseModelData(id: 41, status: 'worker_assigned'),
        ),
      );
      await tester.pumpAndSettle();

      expect(source.fetchBookingCalls, greaterThanOrEqualTo(2));
      expect(find.text('تأكيد الوصول'), findsOneWidget);
      expect(find.text('بدء التنقل'), findsNothing);
      expect(find.text('تم تسجيل بدء التنقل.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('التواصل مع المشرف'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('المشرف: مشرف تجريبي'), findsOneWidget);
      expect(find.text('رقم المشرف: +963944100003'), findsOneWidget);
      expect(find.text('اتصال بالمشرف'), findsOneWidget);
      expect(find.text('رسالة للمشرف'), findsOneWidget);
    },
  );
}

class _FakeOrdersRemoteDataSource extends OrdersRemoteDataSource {
  _FakeOrdersRemoteDataSource() : super(dioNetwork: _UnusedDioNetwork());

  SupervisedWorkerBooking booking = const SupervisedWorkerBooking(
    id: 41,
    bookingNumber: 'CLN-LINKED-001',
    status: 'worker_assigned',
    tasks: [],
    specializedServices: [],
    allowedActions: ['view'],
    canStartTravel: true,
    supervisorName: 'مشرف تجريبي',
    supervisorPhone: '+963944100003',
  );
  int fetchBookingCalls = 0;
  int startTravelCalls = 0;
  Future<StartTravelUsecaseModel> startTravelResult = Future.value(
    StartTravelUsecaseModel(data: StartTravelUsecaseModelData(id: 41)),
  );

  @override
  Future<SupervisedWorkerBooking> fetchSupervisedBooking(int bookingId) async {
    fetchBookingCalls++;
    return booking;
  }

  @override
  Future<WorkerBookingInventory> fetchBookingInventory(int bookingId) async =>
      const WorkerBookingInventory(materials: [], equipment: []);

  @override
  Future<StartTravelUsecaseModel> startTravelUsecase(
    StartTravelUsecaseParams params,
  ) {
    startTravelCalls++;
    return startTravelResult;
  }

  @override
  Future<ArriveModel> arrive(ArriveParams params) async => ArriveModel(
    data: ArriveModelData(id: params.id, arrivedAt: '2026-10-26T08:00:00Z'),
  );
}

class _UnusedDioNetwork implements DioNetwork {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

extension on SupervisedWorkerBooking {
  SupervisedWorkerBooking copyWithAttendance({
    String? startedTravelAt,
    String? arrivedAt,
    required bool canStartTravel,
    required bool canArrive,
  }) => SupervisedWorkerBooking(
    id: id,
    bookingNumber: bookingNumber,
    status: status,
    tasks: tasks,
    specializedServices: specializedServices,
    allowedActions: allowedActions,
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
    neighborhoodName: neighborhoodName,
    supervisorName: supervisorName,
    supervisorPhone: supervisorPhone,
    propertyType: propertyType,
    propertyDetails: propertyDetails,
    startedTravelAt: startedTravelAt,
    arrivedAt: arrivedAt,
    canStartTravel: canStartTravel,
    canArrive: canArrive,
  );
}
