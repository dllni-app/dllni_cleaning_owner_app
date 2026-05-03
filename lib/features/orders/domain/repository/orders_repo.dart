import 'package:common_package/helpers/typedef.dart';
import '../usecases/fetch_orders_usecase_use_case.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../usecases/fetch_order_details_usecase_use_case.dart';
import '../../data/models/fetch_order_details_usecase_model.dart';
import '../usecases/accept_order_usecase_use_case.dart';
import '../../data/models/accept_order_usecase_model.dart';
import '../usecases/start_travel_usecase_use_case.dart';
import '../../data/models/start_travel_usecase_model.dart';
import '../usecases/complete_order_usecase_use_case.dart';
import '../../data/models/complete_order_usecase_model.dart';
import '../usecases/cancel_order_use_case.dart';
import '../../data/models/cancel_order_details_model.dart';
import '../usecases/fetch_extension_requests_usecas_use_case.dart';
import '../../data/models/fetch_extension_requests_usecas_model.dart';
import '../usecases/accept_extension_usecase_use_case.dart';
import '../../data/models/accept_extension_usecase_model.dart';
import '../usecases/reject_extension_usecase_use_case.dart';
import '../../data/models/reject_extension_usecase_model.dart';
import '../usecases/update_availability_usecase_use_case.dart';
import '../../data/models/update_availability_usecase_model.dart';
import '../usecases/reject_order_usecase_use_case.dart';
import '../../data/models/reject_order_usecase_model.dart';
import '../usecases/arrive_use_case.dart';
import '../../data/models/arrive_model.dart';
import '../usecases/post_booking_location_use_case.dart';
import '../../data/models/booking_location_model.dart';
import '../usecases/fetch_security_code_use_case.dart';
import '../../data/models/security_code_model.dart';
import '../usecases/start_work_use_case.dart';
import '../../data/models/start_work_model.dart';

abstract class OrdersRepo {
  DataResponse<FetchOrdersUsecaseModel> fetchOrdersUsecase(FetchOrdersUsecaseParams params);

  DataResponse<FetchOrderDetailsUsecaseModel> fetchOrderDetailsUsecase(FetchOrderDetailsUsecaseParams params);

  DataResponse<AcceptOrderUsecaseModel> acceptOrderUsecase(AcceptOrderUsecaseParams params);

  DataResponse<StartTravelUsecaseModel> startTravelUsecase(StartTravelUsecaseParams params);

  DataResponse<CompleteOrderUsecaseModel> completeOrderUsecase(CompleteOrderUsecaseParams params);

  DataResponse<CancelOrderModel> cancelOrder(CancelOrderParams params);

  DataResponse<FetchExtensionRequestsUsecasModel> fetchExtensionRequestsUsecas(FetchExtensionRequestsUsecasParams params);

  DataResponse<AcceptExtensionUsecaseModel> acceptExtensionUsecase(AcceptExtensionUsecaseParams params);

  DataResponse<RejectExtensionUsecaseModel> rejectExtensionUsecase(RejectExtensionUsecaseParams params);

  DataResponse<UpdateAvailabilityUsecaseModel> updateAvailabilityUsecase(UpdateAvailabilityUsecaseParams params);

  DataResponse<RejectOrderUsecaseModel> rejectOrderUsecase(RejectOrderUsecaseParams params);

  DataResponse<ArriveModel> arrive(ArriveParams params);

  DataResponse<BookingLocationOkModel> postBookingLocation(PostBookingLocationParams params);

  DataResponse<SecurityCodeModel> fetchSecurityCode(FetchSecurityCodeParams params);

  DataResponse<StartWorkModel> startWork(StartWorkParams params);
}
