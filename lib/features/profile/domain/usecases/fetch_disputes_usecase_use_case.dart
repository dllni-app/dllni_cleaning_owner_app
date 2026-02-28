import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/profile_repo.dart';
import '../../data/models/fetch_disputes_usecase_model.dart';

@lazySingleton
class FetchDisputesUsecaseUseCase implements UseCase<FetchDisputesUsecaseModel, FetchDisputesUsecaseParams> {
  final ProfileRepo profile;

  FetchDisputesUsecaseUseCase({required this.profile});

  @override
  DataResponse<FetchDisputesUsecaseModel> call(FetchDisputesUsecaseParams params) {
    return profile.fetchDisputesUsecase(params);
  }
}

class FetchDisputesUsecaseParams with Params {

  final int page;
  final String? status;

  FetchDisputesUsecaseParams({required this.page, this.status});

  @override
  QueryParams getParams() => {
    "filter[status]": status,
    "perPage": "10",
    "page": page,
  }..removeWhere((key, val) => val == null);
}
