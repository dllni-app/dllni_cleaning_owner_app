import 'package:common_package/helpers/typedef.dart';
import 'package:dartz/dartz.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/accept_extension_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/accept_order_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/arrive_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/booking_location_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cancel_order_details_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/complete_order_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_extension_requests_usecas_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/reject_extension_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/reject_order_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/security_code_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/start_travel_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/start_work_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/update_availability_usecase_model.dart';
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
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrdersBloc realtime hydration', () {
    test(
      'hydrates orders list item from realtime payload without refetch',
      () async {
        final repo = _FakeOrdersRepo();
        final bloc = _buildBloc(repo);

        bloc.add(
          FetchOrdersUsecaseEvent(
            params: FetchOrdersUsecaseParams(
              page: 1,
              status: CleaningBookingStatus.workerAssigned,
            ),
            isReload: true,
          ),
        );
        await _flushBlocQueue();
        expect(bloc.state.ordersUsecase?.list.first.id, 42);
        expect(
          bloc.state.ordersUsecase?.list.first.status,
          CleaningBookingStatus.workerAssigned,
        );

        bloc.add(
          HydrateOrderListFromRealtimeEvent(
            eventName: 'WorkerArrived',
            payload: <String, dynamic>{
              'cleaningBookingId': 42,
              'status': CleaningBookingStatus.awaitingStartVerification,
              'arrivedAt': '2026-05-13T00:00:00Z',
            },
          ),
        );
        await _flushBlocQueue();

        expect(
          bloc.state.ordersUsecase?.list.first.status,
          CleaningBookingStatus.awaitingStartVerification,
        );
        expect(
          bloc.state.ordersUsecase?.list.first.arrivedAt,
          '2026-05-13T00:00:00Z',
        );
        await bloc.close();
      },
    );

    test(
      'hydrates order details status from realtime decision payload',
      () async {
        final repo = _FakeOrdersRepo();
        final bloc = _buildBloc(repo);

        bloc.add(
          FetchOrderDetailsUsecaseEvent(
            params: FetchOrderDetailsUsecaseParams(id: 42),
          ),
        );
        await _flushBlocQueue();
        expect(
          bloc.state.orderDetailsUsecase?.data?.status,
          CleaningBookingStatus.workerAssigned,
        );

        bloc.add(
          HydrateOrderDetailsFromRealtimeEvent(
            bookingId: 42,
            eventName: 'CompletionDecisionMade',
            payload: <String, dynamic>{
              'cleaningBookingId': 42,
              'decision': 'approved',
            },
          ),
        );
        await _flushBlocQueue();

        expect(
          bloc.state.orderDetailsUsecase?.data?.status,
          CleaningBookingStatus.completed,
        );
        await bloc.close();
      },
    );
  });
}

OrdersBloc _buildBloc(_FakeOrdersRepo repo) {
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

Future<void> _flushBlocQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeOrdersRepo implements OrdersRepo {
  @override
  DataResponse<AcceptExtensionUsecaseModel> acceptExtensionUsecase(
    AcceptExtensionUsecaseParams params,
  ) async {
    return Right(AcceptExtensionUsecaseModel());
  }

  @override
  DataResponse<AcceptOrderUsecaseModel> acceptOrderUsecase(
    AcceptOrderUsecaseParams params,
  ) async {
    return Right(AcceptOrderUsecaseModel());
  }

  @override
  DataResponse<ArriveModel> arrive(ArriveParams params) async {
    return Right(ArriveModel());
  }

  @override
  DataResponse<CancelOrderModel> cancelOrder(CancelOrderParams params) async {
    return Right(CancelOrderModel());
  }

  @override
  DataResponse<CompleteOrderUsecaseModel> completeOrderUsecase(
    CompleteOrderUsecaseParams params,
  ) async {
    return Right(CompleteOrderUsecaseModel());
  }

  @override
  DataResponse<FetchExtensionRequestsUsecasModel> fetchExtensionRequestsUsecas(
    FetchExtensionRequestsUsecasParams params,
  ) async {
    return Right(FetchExtensionRequestsUsecasModel());
  }

  @override
  DataResponse<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(
    FetchOrderDetailsUsecaseParams params,
  ) async {
    return Right(
      FetchOrderDetailsUsecaseModel(
        data: FetchOrderDetailsUsecaseModelData(
          id: 42,
          status: CleaningBookingStatus.workerAssigned,
        ),
      ),
    );
  }

  @override
  DataResponse<FetchOrdersUsecaseModel> fetchOrdersUsecase(
    FetchOrdersUsecaseParams params,
  ) async {
    return Right(
      FetchOrdersUsecaseModel(
        data: <FetchOrdersUsecaseModelDataItem>[
          FetchOrdersUsecaseModelDataItem(
            id: 42,
            status: CleaningBookingStatus.workerAssigned,
          ),
        ],
      ),
    );
  }

  @override
  DataResponse<SecurityCodeModel> fetchSecurityCode(
    FetchSecurityCodeParams params,
  ) async {
    return Right(
      SecurityCodeModel(data: SecurityCodeData(securityCode: '1234')),
    );
  }

  @override
  DataResponse<BookingLocationOkModel> postBookingLocation(
    PostBookingLocationParams params,
  ) async {
    return Right(BookingLocationOkModel(ok: true));
  }

  @override
  DataResponse<RejectExtensionUsecaseModel> rejectExtensionUsecase(
    RejectExtensionUsecaseParams params,
  ) async {
    return Right(RejectExtensionUsecaseModel());
  }

  @override
  DataResponse<RejectOrderUsecaseModel> rejectOrderUsecase(
    RejectOrderUsecaseParams params,
  ) async {
    return Right(RejectOrderUsecaseModel());
  }

  @override
  DataResponse<StartTravelUsecaseModel> startTravelUsecase(
    StartTravelUsecaseParams params,
  ) async {
    return Right(StartTravelUsecaseModel());
  }

  @override
  DataResponse<StartWorkModel> startWork(StartWorkParams params) async {
    return Right(StartWorkModel());
  }

  @override
  DataResponse<UpdateAvailabilityUsecaseModel> updateAvailabilityUsecase(
    UpdateAvailabilityUsecaseParams params,
  ) async {
    return Right(UpdateAvailabilityUsecaseModel());
  }
}
