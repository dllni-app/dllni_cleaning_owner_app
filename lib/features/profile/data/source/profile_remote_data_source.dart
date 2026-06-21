import 'package:common_package/helpers/dio_network.dart';
import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/api_handler.dart';
import 'package:common_package/helpers/typedef.dart';
import '../models/fetch_worker_profile_usecase_model.dart';
import '../../domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import '../models/fetch_disputes_usecase_model.dart';
import '../../domain/usecases/fetch_disputes_usecase_use_case.dart';
import '../models/fetch_dispute_details_usecase_model.dart';
import '../../domain/usecases/fetch_dispute_details_usecase_use_case.dart';
import '../models/update_dispute_model.dart';
import '../../domain/usecases/update_dispute_use_case.dart';
import '../models/fetch_worker_statistics_model.dart';
import '../../domain/usecases/fetch_worker_statistics_use_case.dart';
import '../models/worker_work_areas_model.dart';
import '../../domain/usecases/update_worker_work_areas_use_case.dart';
import '../models/update_worker_profile_model.dart';
import '../../domain/usecases/update_worker_profile_use_case.dart';
import '../models/notification_api_models.dart';
import '../models/fetch_deposit_account_usecase_model.dart';
import '../models/fetch_deposit_transactions_usecase_model.dart';
import '../../domain/usecases/fetch_notifications_use_case.dart';
import '../../domain/usecases/fetch_deposit_transactions_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';
import '../models/fetch_worker_reviews_model.dart';
import '../../domain/usecases/fetch_worker_reviews_use_case.dart';
import '../models/cleaning_neighborhoods_response_model.dart';
import '../../domain/usecases/fetch_cleaning_neighborhoods_use_case.dart';

@lazySingleton
class ProfileRemoteDataSource with HandlingApiManager {
  final DioNetwork dioNetwork;

  ProfileRemoteDataSource({required this.dioNetwork});

  Future<FetchWorkerProfileUsecaseModel> fetchWorkerProfileUsecase(
    FetchWorkerProfileUsecaseParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning/worker/profile',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchWorkerProfileUsecaseModelFromJson,
    );
  }

  Future<FetchDisputesUsecaseModel> fetchDisputesUsecase(
    FetchDisputesUsecaseParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/disputes',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchDisputesUsecaseModelFromJson,
    );
  }

  Future<FetchDisputeDetailsUsecaseModel> fetchDisputeDetailsUsecase(
    FetchDisputeDetailsUsecaseParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/disputes/${params.id}',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchDisputeDetailsUsecaseModelFromJson,
    );
  }

  Future<UpdateDisputeModel> updateDispute(UpdateDisputeParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.putData(
        endPoint: '/api/v1/disputes/${params.disputeId}',
        params: params.getParams(),
        data: params.getBody(),
      ),
      jsonConvert: updateDisputeModelFromJson,
    );
  }

  Future<FetchWorkerStatisticsModel> fetchWorkerStatistics(
    FetchWorkerStatisticsParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning/worker/statistics',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchWorkerStatisticsModelFromJson,
    );
  }

  Future<WorkerWorkAreasModel> updateWorkerWorkAreas(
    UpdateWorkerWorkAreasParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.putData(
        endPoint: '/api/v1/cleaning/worker/account/work-areas',
        params: params.getParams(),
        data: params.getBody(),
      ),
      jsonConvert: workerWorkAreasModelFromJson,
    );
  }

  Future<UpdateWorkerProfileModel> updateWorkerProfile(
    UpdateWorkerProfileParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.putData(
        endPoint: '/api/v1/cleaning/worker/account/profile',
        params: params.getParams(),
        data: params.getBody(),
      ),
      jsonConvert: updateWorkerProfileModelFromJson,
    );
  }

  Future<FetchNotificationsPageModel> fetchNotifications(
    FetchNotificationsParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/notifications',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchNotificationsPageModelFromJson,
    );
  }

  Future<FetchDepositAccountUsecaseModel> fetchDepositAccount(NoParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning/worker/account/deposit',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchDepositAccountUsecaseModelFromJson,
    );
  }

  Future<FetchDepositTransactionsUsecaseModel> fetchDepositTransactions(
    FetchDepositTransactionsParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning/worker/account/deposit/transactions',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchDepositTransactionsUsecaseModelFromJson,
    );
  }

  Future<ActionResultModel> markAllNotificationsRead(NoParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.patchData(
        endPoint: '/api/v1/notifications/read-all',
        data: params.getBody().isEmpty ? {} : params.getBody(),
      ),
      jsonConvert: actionResultModelFromJson,
    );
  }

  Future<ActionResultModel> markNotificationRead(
    MarkNotificationReadParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.patchData(
        endPoint: '/api/v1/notifications/${params.notificationId}/read',
        data: params.getBody().isEmpty ? {} : params.getBody(),
      ),
      jsonConvert: actionResultModelFromJson,
    );
  }

  Future<FetchWorkerReviewsModel> fetchWorkerReviews(
    FetchWorkerReviewsParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning/worker/reviews',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchWorkerReviewsModelFromJson,
    );
  }

  Future<CleaningNeighborhoodsResponseModel> fetchCleaningNeighborhoods(
    FetchCleaningNeighborhoodsParams params,
  ) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning/neighborhoods',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: cleaningNeighborhoodsResponseModelFromJson,
    );
  }
}
