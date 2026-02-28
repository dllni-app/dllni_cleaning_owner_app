import 'package:common_package/helpers/typedef.dart';
import '../usecases/fetch_worker_profile_usecase_use_case.dart';
import '../../data/models/fetch_worker_profile_usecase_model.dart';
import '../usecases/fetch_disputes_usecase_use_case.dart';
import '../../data/models/fetch_disputes_usecase_model.dart';
import '../usecases/fetch_dispute_details_usecase_use_case.dart';
import '../../data/models/fetch_dispute_details_usecase_model.dart';
abstract class ProfileRepo {
  DataResponse<FetchWorkerProfileUsecaseModel> fetchWorkerProfileUsecase(FetchWorkerProfileUsecaseParams params);

  DataResponse<FetchDisputesUsecaseModel> fetchDisputesUsecase(FetchDisputesUsecaseParams params);

  DataResponse<FetchDisputeDetailsUsecaseModel> fetchDisputeDetailsUsecase(FetchDisputeDetailsUsecaseParams params);
}
