import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/profile_repo.dart';
import '../../data/models/fetch_dispute_details_usecase_model.dart';

@lazySingleton
class FetchDisputeDetailsUsecaseUseCase implements UseCase<FetchDisputeDetailsUsecaseModel, FetchDisputeDetailsUsecaseParams> {

  final ProfileRepo profile;

  FetchDisputeDetailsUsecaseUseCase({required this.profile});

  @override
  DataResponse<FetchDisputeDetailsUsecaseModel> call(FetchDisputeDetailsUsecaseParams params) {
    return profile.fetchDisputeDetailsUsecase(params);
  }
}

class FetchDisputeDetailsUsecaseParams with Params{
  final int id;

  FetchDisputeDetailsUsecaseParams({required this.id});
}
