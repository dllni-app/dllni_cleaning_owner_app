import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/error_handler.dart';

import '../../domain/repository/profile_repo.dart';
import 'package:common_package/helpers/typedef.dart';
import '../source/profile_remote_data_source.dart';
import '../../domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import '../models/fetch_worker_profile_usecase_model.dart';
import '../../domain/usecases/fetch_disputes_usecase_use_case.dart';
import '../models/fetch_disputes_usecase_model.dart';
import '../../domain/usecases/fetch_dispute_details_usecase_use_case.dart';
import '../models/fetch_dispute_details_usecase_model.dart';
import '../../domain/usecases/update_dispute_use_case.dart';
import '../models/update_dispute_model.dart';
import '../../domain/usecases/fetch_worker_statistics_use_case.dart';
import '../models/fetch_worker_statistics_model.dart';
import '../../domain/usecases/update_worker_work_areas_use_case.dart';
import '../models/worker_work_areas_model.dart';
import '../../domain/usecases/update_worker_profile_use_case.dart';
import '../models/update_worker_profile_model.dart';
import '../../domain/usecases/fetch_notifications_use_case.dart';
import '../../domain/usecases/fetch_deposit_transactions_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';
import '../models/fetch_deposit_account_usecase_model.dart';
import '../models/fetch_deposit_transactions_usecase_model.dart';
import '../models/notification_api_models.dart';
import '../../domain/usecases/fetch_worker_reviews_use_case.dart';
import '../models/fetch_worker_reviews_model.dart';
import '../../domain/usecases/fetch_cleaning_neighborhoods_use_case.dart';
import '../models/cleaning_neighborhoods_response_model.dart';

@LazySingleton(as: ProfileRepo)
class ProfileRepoImpl with HandlingException implements ProfileRepo {
  final ProfileRemoteDataSource profileRemoteDataSource;

  ProfileRepoImpl({required this.profileRemoteDataSource});

  @override
  DataResponse<FetchWorkerProfileUsecaseModel> fetchWorkerProfileUsecase(
    FetchWorkerProfileUsecaseParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchWorkerProfileUsecase(params),
    );
  }

  @override
  DataResponse<FetchDisputesUsecaseModel> fetchDisputesUsecase(
    FetchDisputesUsecaseParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchDisputesUsecase(params),
    );
  }

  @override
  DataResponse<FetchDisputeDetailsUsecaseModel> fetchDisputeDetailsUsecase(
    FetchDisputeDetailsUsecaseParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchDisputeDetailsUsecase(params),
    );
  }

  @override
  DataResponse<UpdateDisputeModel> updateDispute(UpdateDisputeParams params) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.updateDispute(params),
    );
  }

  @override
  DataResponse<FetchWorkerStatisticsModel> fetchWorkerStatistics(
    FetchWorkerStatisticsParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchWorkerStatistics(params),
    );
  }

  @override
  DataResponse<WorkerWorkAreasModel> updateWorkerWorkAreas(
    UpdateWorkerWorkAreasParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.updateWorkerWorkAreas(params),
    );
  }

  @override
  DataResponse<UpdateWorkerProfileModel> updateWorkerProfile(
    UpdateWorkerProfileParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.updateWorkerProfile(params),
    );
  }

  @override
  DataResponse<FetchNotificationsPageModel> fetchNotifications(
    FetchNotificationsParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchNotifications(params),
    );
  }

  @override
  DataResponse<FetchDepositAccountUsecaseModel> fetchDepositAccount(
    NoParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchDepositAccount(params),
    );
  }

  @override
  DataResponse<FetchDepositTransactionsUsecaseModel> fetchDepositTransactions(
    FetchDepositTransactionsParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchDepositTransactions(params),
    );
  }

  @override
  DataResponse<ActionResultModel> markAllNotificationsRead(NoParams params) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.markAllNotificationsRead(params),
    );
  }

  @override
  DataResponse<ActionResultModel> markNotificationRead(
    MarkNotificationReadParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.markNotificationRead(params),
    );
  }

  @override
  DataResponse<FetchWorkerReviewsModel> fetchWorkerReviews(
    FetchWorkerReviewsParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchWorkerReviews(params),
    );
  }

  @override
  DataResponse<CleaningNeighborhoodsResponseModel> fetchCleaningNeighborhoods(
    FetchCleaningNeighborhoodsParams params,
  ) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchCleaningNeighborhoods(params),
    );
  }
}
