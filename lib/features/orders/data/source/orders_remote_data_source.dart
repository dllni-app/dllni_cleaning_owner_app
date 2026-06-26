import 'package:common_package/helpers/dio_network.dart';
import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/api_handler.dart';
import '../models/fetch_orders_usecase_model.dart';
import '../../domain/usecases/fetch_orders_usecase_use_case.dart';
import '../models/fetch_order_details_usecase_model.dart';
import '../../domain/usecases/fetch_order_details_usecase_use_case.dart';
import '../models/accept_order_usecase_model.dart';
import '../../domain/usecases/accept_order_usecase_use_case.dart';
import '../models/start_travel_usecase_model.dart';
import '../../domain/usecases/start_travel_usecase_use_case.dart';
import '../models/complete_order_usecase_model.dart';
import '../../domain/usecases/complete_order_usecase_use_case.dart';
import '../models/cancel_order_details_model.dart';
import '../../domain/usecases/cancel_order_use_case.dart';
import '../models/fetch_extension_requests_usecas_model.dart';
import '../../domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import '../models/accept_extension_usecase_model.dart';
import '../../domain/usecases/accept_extension_usecase_use_case.dart';
import '../models/reject_extension_usecase_model.dart';
import '../../domain/usecases/reject_extension_usecase_use_case.dart';
import '../models/update_availability_usecase_model.dart';
import '../../domain/usecases/update_availability_usecase_use_case.dart';
import '../models/reject_order_usecase_model.dart';
import '../../domain/usecases/reject_order_usecase_use_case.dart';
import '../models/arrive_model.dart';
import '../../domain/usecases/arrive_use_case.dart';
import '../models/booking_location_model.dart';
import '../../domain/usecases/post_booking_location_use_case.dart';
import '../models/security_code_model.dart';
import '../../domain/usecases/fetch_security_code_use_case.dart';
import '../models/start_work_model.dart';
import '../../domain/usecases/start_work_use_case.dart';
import '../models/booking_price_adjustment_request_model.dart';
import '../../domain/usecases/request_booking_price_adjustment_use_case.dart';
import '../models/sos_alert_models.dart';
import '../../domain/usecases/create_cleaning_booking_sos_use_case.dart';

@lazySingleton
class OrdersRemoteDataSource with HandlingApiManager {
  final DioNetwork dioNetwork;

  OrdersRemoteDataSource({required this.dioNetwork});

  Future<FetchOrdersUsecaseModel> fetchOrdersUsecase(FetchOrdersUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () =>
          dioNetwork.getData(endPoint: '/api/v1/cleaning-bookings', params: params.getParams(), data: params.getBody().isEmpty ? null : params.getBody()),
      jsonConvert: fetchOrdersUsecaseModelFromJson,
    );
  }

  Future<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(FetchOrderDetailsUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning-bookings/${params.id}',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchOrderDetailsUsecaseModelFromJson,
    );
  }

  Future<AcceptOrderUsecaseModel> acceptOrderUsecase(AcceptOrderUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(endPoint: '/api/v1/cleaning-bookings/${params.id}/accept', data: params.getBody(), params: params.getParams()),
      jsonConvert: acceptOrderUsecaseModelFromJson,
    );
  }

  Future<StartTravelUsecaseModel> startTravelUsecase(StartTravelUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(endPoint: '/api/v1/cleaning-bookings/${params.id}/start-travel', data: params.getBody(), params: params.getParams()),
      jsonConvert: startTravelUsecaseModelFromJson,
    );
  }

  Future<CompleteOrderUsecaseModel> completeOrderUsecase(CompleteOrderUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () =>
          dioNetwork.postData(endPoint: '/api/v1/cleaning-bookings/${params.id}/complete', data: params.getBody(), params: params.getParams()),
      jsonConvert: completeOrderUsecaseModelFromJson,
    );
  }

  Future<CancelOrderModel> cancelOrder(CancelOrderParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(endPoint: '/api/v1/cleaning-bookings/${params.id}/cancel', data: params.getBody(), params: params.getParams()),
      jsonConvert: cancelOrderModelFromJson,
    );
  }

  Future<FetchExtensionRequestsUsecasModel> fetchExtensionRequestsUsecas(FetchExtensionRequestsUsecasParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning-time-warnings',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchExtensionRequestsUsecasModelFromJson,
    );
  }

  Future<AcceptExtensionUsecaseModel> acceptExtensionUsecase(AcceptExtensionUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () =>
          dioNetwork.postData(endPoint: '/api/v1/cleaning-time-warnings/${params.id}/accept', data: params.getBody(), params: params.getParams()),
      jsonConvert: acceptExtensionUsecaseModelFromJson,
    );
  }

  Future<RejectExtensionUsecaseModel> rejectExtensionUsecase(RejectExtensionUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () =>
          dioNetwork.postData(endPoint: '/api/v1/cleaning-time-warnings/${params.id}/reject', data: params.getBody(), params: params.getParams()),
      jsonConvert: rejectExtensionUsecaseModelFromJson,
    );
  }

  Future<UpdateAvailabilityUsecaseModel> updateAvailabilityUsecase(UpdateAvailabilityUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.putData(endPoint: '/api/v1/workers/${params.id}', data: params.getBody(), params: params.getParams()),
      jsonConvert: updateAvailabilityUsecaseModelFromJson,
    );
  }

  Future<RejectOrderUsecaseModel> rejectOrderUsecase(RejectOrderUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(endPoint: '/api/v1/cleaning-bookings/${params.id}/reject', data: params.getBody(), params: params.getParams()),
      jsonConvert: rejectOrderUsecaseModelFromJson,
    );
  }


  Future<ArriveModel> arrive(ArriveParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(endPoint: '/api/v1/cleaning-bookings/${params.id}/arrive', data: params.getBody(), params: params.getParams()),
      jsonConvert: arriveModelFromJson,
    );
  }

  Future<BookingLocationOkModel> postBookingLocation(PostBookingLocationParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(
        endPoint: '/api/v1/cleaning-bookings/${params.id}/location',
        data: params.getBody(),
        params: params.getParams(),
      ),
      jsonConvert: bookingLocationOkModelFromJson,
    );
  }

  Future<SecurityCodeModel> fetchSecurityCode(FetchSecurityCodeParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning-bookings/${params.id}/security-code',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: securityCodeModelFromJson,
    );
  }

  Future<StartWorkModel> startWork(StartWorkParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(
        endPoint: '/api/v1/cleaning-bookings/${params.id}/start-work',
        data: params.getBody(),
        params: params.getParams(),
      ),
      jsonConvert: startWorkModelFromJson,
    );
  }

  Future<BookingPriceAdjustmentRequestModel> requestBookingPriceAdjustment(
    RequestBookingPriceAdjustmentParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(
        endPoint: '/api/v1/cleaning-bookings/${params.id}/price-adjustment-requests',
        data: params.getBody(),
        params: params.getParams(),
      ),
      jsonConvert: bookingPriceAdjustmentRequestModelFromJson,
    );
  }

  Future<CleaningSosAlertModel> createCleaningBookingSos(
    CreateCleaningBookingSosParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(
        endPoint: '/api/v1/cleaning-bookings/${params.cleaningBookingId}/sos',
        data: params.getBody(),
      ),
      jsonConvert: cleaningSosAlertModelFromJson,
    );
  }
}
