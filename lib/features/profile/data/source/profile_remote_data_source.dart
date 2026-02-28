import 'package:common_package/helpers/dio_network.dart';
import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/api_handler.dart';
import '../models/fetch_worker_profile_usecase_model.dart';
import '../../domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import '../models/fetch_disputes_usecase_model.dart';
import '../../domain/usecases/fetch_disputes_usecase_use_case.dart';
import '../models/fetch_dispute_details_usecase_model.dart';
import '../../domain/usecases/fetch_dispute_details_usecase_use_case.dart';

@lazySingleton
class ProfileRemoteDataSource with HandlingApiManager {
  final DioNetwork dioNetwork;

  ProfileRemoteDataSource({required this.dioNetwork});

  Future<FetchWorkerProfileUsecaseModel> fetchWorkerProfileUsecase(FetchWorkerProfileUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning/worker/profile',
        params: params.getParams(),
        data: params.getBody().isEmpty ? null : params.getBody(),
      ),
      jsonConvert: fetchWorkerProfileUsecaseModelFromJson,
    );
  }

  Future<FetchDisputesUsecaseModel> fetchDisputesUsecase(FetchDisputesUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(endPoint: '/api/v1/disputes', params: params.getParams(), data: params.getBody().isEmpty ? null : params.getBody()),
      jsonConvert: fetchDisputesUsecaseModelFromJson,
    );
  }

  Future<FetchDisputeDetailsUsecaseModel> fetchDisputeDetailsUsecase(FetchDisputeDetailsUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () =>
          dioNetwork.getData(endPoint: '/api/v1/disputes/${params.id}', params: params.getParams(), data: params.getBody().isEmpty ? null : params.getBody()),
      jsonConvert: fetchDisputeDetailsUsecaseModelFromJson,
    );
  }
}
