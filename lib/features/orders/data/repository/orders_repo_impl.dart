import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/error_handler.dart';

import '../../domain/repository/orders_repo.dart';
import 'package:common_package/helpers/typedef.dart';
import '../source/orders_remote_data_source.dart';
import '../../domain/usecases/fetch_orders_usecase_use_case.dart';
import '../models/fetch_orders_usecase_model.dart';
import '../../domain/usecases/fetch_order_details_usecase_use_case.dart';
import '../models/fetch_order_details_usecase_model.dart';
import '../../domain/usecases/accept_order_usecase_use_case.dart';
import '../models/accept_order_usecase_model.dart';
import '../../domain/usecases/start_travel_usecase_use_case.dart';
import '../models/start_travel_usecase_model.dart';
import '../../domain/usecases/complete_order_usecase_use_case.dart';
import '../models/complete_order_usecase_model.dart';
import '../../domain/usecases/cancel_order_use_case.dart';
import '../models/cancel_order_details_model.dart';
import '../../domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import '../models/fetch_extension_requests_usecas_model.dart';
import '../../domain/usecases/accept_extension_usecase_use_case.dart';
import '../models/accept_extension_usecase_model.dart';
import '../../domain/usecases/reject_extension_usecase_use_case.dart';
import '../models/reject_extension_usecase_model.dart';
import '../../domain/usecases/update_availability_usecase_use_case.dart';
import '../models/update_availability_usecase_model.dart';
import '../../domain/usecases/reject_order_usecase_use_case.dart';
import '../models/reject_order_usecase_model.dart';
import '../../domain/usecases/arrive_use_case.dart';
import '../models/arrive_model.dart';
import '../../domain/usecases/post_booking_location_use_case.dart';
import '../models/booking_location_model.dart';
import '../../domain/usecases/fetch_security_code_use_case.dart';
import '../models/security_code_model.dart';
import '../../domain/usecases/start_work_use_case.dart';
import '../models/start_work_model.dart';

@LazySingleton(as: OrdersRepo)
class OrdersRepoImpl with HandlingException implements OrdersRepo {
  final OrdersRemoteDataSource ordersRemoteDataSource;

  OrdersRepoImpl({required this.ordersRemoteDataSource});

  @override
  DataResponse<FetchOrdersUsecaseModel> fetchOrdersUsecase(FetchOrdersUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.fetchOrdersUsecase(params),
    );
  }

  @override
  DataResponse<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(FetchOrderDetailsUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.fetchOrderDetailsUsecase(params),
    );
  }

  @override
  DataResponse<AcceptOrderUsecaseModel> acceptOrderUsecase(AcceptOrderUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.acceptOrderUsecase(params),
    );
  }

  @override
  DataResponse<StartTravelUsecaseModel> startTravelUsecase(StartTravelUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.startTravelUsecase(params),
    );
  }

  @override
  DataResponse<CompleteOrderUsecaseModel> completeOrderUsecase(CompleteOrderUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.completeOrderUsecase(params),
    );
  }

  @override
  DataResponse<CancelOrderModel> cancelOrder(CancelOrderParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.cancelOrder(params),
    );
  }

  @override
  DataResponse<FetchExtensionRequestsUsecasModel> fetchExtensionRequestsUsecas(FetchExtensionRequestsUsecasParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.fetchExtensionRequestsUsecas(params),
    );
  }

  @override
  DataResponse<AcceptExtensionUsecaseModel> acceptExtensionUsecase(AcceptExtensionUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.acceptExtensionUsecase(params),
    );
  }

  @override
  DataResponse<RejectExtensionUsecaseModel> rejectExtensionUsecase(RejectExtensionUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.rejectExtensionUsecase(params),
    );
  }

  @override
  DataResponse<UpdateAvailabilityUsecaseModel> updateAvailabilityUsecase(UpdateAvailabilityUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.updateAvailabilityUsecase(params),
    );
  }

  @override
  DataResponse<RejectOrderUsecaseModel> rejectOrderUsecase(RejectOrderUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.rejectOrderUsecase(params),
    );
  }

  @override
  DataResponse<ArriveModel> arrive(ArriveParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.arrive(params),
    );
  }

  @override
  DataResponse<BookingLocationOkModel> postBookingLocation(PostBookingLocationParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.postBookingLocation(params),
    );
  }

  @override
  DataResponse<SecurityCodeModel> fetchSecurityCode(FetchSecurityCodeParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.fetchSecurityCode(params),
    );
  }

  @override
  DataResponse<StartWorkModel> startWork(StartWorkParams params) {
    return wrapHandlingException(
      tryCall: () => ordersRemoteDataSource.startWork(params),
    );
  }
}

