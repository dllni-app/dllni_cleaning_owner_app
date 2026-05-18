import 'package:common_package/helpers/typedef.dart';
import '../usecases/fetch_worker_profile_usecase_use_case.dart';
import '../../data/models/fetch_worker_profile_usecase_model.dart';
import '../usecases/fetch_disputes_usecase_use_case.dart';
import '../../data/models/fetch_disputes_usecase_model.dart';
import '../usecases/fetch_dispute_details_usecase_use_case.dart';
import '../../data/models/fetch_dispute_details_usecase_model.dart';
import '../usecases/update_dispute_use_case.dart';
import '../../data/models/update_dispute_model.dart';
import '../usecases/fetch_worker_statistics_use_case.dart';
import '../../data/models/fetch_worker_statistics_model.dart';
import '../usecases/update_worker_work_areas_use_case.dart';
import '../../data/models/worker_work_areas_model.dart';
import '../usecases/update_worker_profile_use_case.dart';
import '../../data/models/update_worker_profile_model.dart';
import '../usecases/fetch_notifications_use_case.dart';
import '../usecases/mark_notification_read_use_case.dart';
import '../../data/models/notification_api_models.dart';

abstract class ProfileRepo {
  DataResponse<FetchWorkerProfileUsecaseModel> fetchWorkerProfileUsecase(FetchWorkerProfileUsecaseParams params);

  DataResponse<FetchDisputesUsecaseModel> fetchDisputesUsecase(FetchDisputesUsecaseParams params);

  DataResponse<FetchDisputeDetailsUsecaseModel> fetchDisputeDetailsUsecase(FetchDisputeDetailsUsecaseParams params);

  DataResponse<UpdateDisputeModel> updateDispute(UpdateDisputeParams params);

  DataResponse<FetchWorkerStatisticsModel> fetchWorkerStatistics(FetchWorkerStatisticsParams params);

  DataResponse<WorkerWorkAreasModel> updateWorkerWorkAreas(UpdateWorkerWorkAreasParams params);

  DataResponse<UpdateWorkerProfileModel> updateWorkerProfile(UpdateWorkerProfileParams params);

  DataResponse<FetchNotificationsPageModel> fetchNotifications(FetchNotificationsParams params);

  DataResponse<ActionResultModel> markAllNotificationsRead(NoParams params);

  DataResponse<ActionResultModel> markNotificationRead(MarkNotificationReadParams params);
}
