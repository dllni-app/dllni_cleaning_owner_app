import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/profile_repo.dart';
import '../../data/models/fetch_worker_profile_usecase_model.dart';

@lazySingleton
class FetchWorkerProfileUsecaseUseCase implements UseCase<FetchWorkerProfileUsecaseModel, FetchWorkerProfileUsecaseParams> {

  final ProfileRepo profile;

  FetchWorkerProfileUsecaseUseCase({required this.profile});

  @override
  DataResponse<FetchWorkerProfileUsecaseModel> call(FetchWorkerProfileUsecaseParams params) {
    return profile.fetchWorkerProfileUsecase(params);
  }
}

class FetchWorkerProfileUsecaseParams with Params{}
