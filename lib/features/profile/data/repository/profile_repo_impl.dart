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

@LazySingleton(as: ProfileRepo)
class ProfileRepoImpl with HandlingException implements ProfileRepo {
  final ProfileRemoteDataSource profileRemoteDataSource;

  ProfileRepoImpl({required this.profileRemoteDataSource});

  @override
  DataResponse<FetchWorkerProfileUsecaseModel> fetchWorkerProfileUsecase(FetchWorkerProfileUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchWorkerProfileUsecase(params),
    );
  }

  @override
  DataResponse<FetchDisputesUsecaseModel> fetchDisputesUsecase(FetchDisputesUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchDisputesUsecase(params),
    );
  }

  @override
  DataResponse<FetchDisputeDetailsUsecaseModel> fetchDisputeDetailsUsecase(FetchDisputeDetailsUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => profileRemoteDataSource.fetchDisputeDetailsUsecase(params),
    );
  }}

