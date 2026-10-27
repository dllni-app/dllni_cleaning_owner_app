import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
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
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../support/finish_widget_cleanup.dart';

void main() {
  testWidgets('accepted pre-travel details do not reveal call or SMS actions', (
    tester,
  ) async {
    final repo = _NoopOrdersRepo();
    final bloc = OrdersBloc(
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
    final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
      'id': 17,
      'bookingNumber': 'CLN-TEST-TRAVEL',
      'status': 'worker_assigned',
      'worker_order_status': 'accepted_waiting_for_order_start',
      'worker_order_status_label': 'accepted waiting for order start',
      'scheduledDate': '2026-11-01',
      'scheduledTime': '09:00',
      'customer': <String, dynamic>{
        'name': 'عميل تجريبي',
        'phone': '+963944111111',
      },
      'myAssignment': <String, dynamic>{
        'status': 'accepted_waiting_for_order_start',
        'acceptedAt': '2026-10-27T09:00:00+03:00',
        'workerAmount': 160,
      },
    });

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(360, 690),
        builder: (context, _) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OrderDetailsBody(bloc: bloc, index: 0, order: order),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ملخص مهمتي'), findsOneWidget);
    expect(find.text('تم القبول - بانتظار بدء الطلب'), findsOneWidget);
    expect(find.text('التواصل مع العميل'), findsNothing);
    expect(find.text('تظهر وسائل التواصل بعد قبولك للمهمة.'), findsNothing);
    expect(find.text('رسالة SMS'), findsNothing);
    expect(find.text('اتصال'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await finishWidgetCleanup(tester, bloc.close());
  });
}

class _NoopOrdersRepo implements OrdersRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
