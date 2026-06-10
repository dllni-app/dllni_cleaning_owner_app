import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fetch_worker_reviews_model.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class FetchWorkerReviewsUseCase
    implements UseCase<FetchWorkerReviewsModel, FetchWorkerReviewsParams> {
  final ProfileRepo profileRepo;

  FetchWorkerReviewsUseCase({required this.profileRepo});

  @override
  DataResponse<FetchWorkerReviewsModel> call(FetchWorkerReviewsParams params) {
    return profileRepo.fetchWorkerReviews(params);
  }
}

class FetchWorkerReviewsParams with Params {
  final int page;
  final int perPage;

  FetchWorkerReviewsParams({this.page = 1, this.perPage = 20});

  @override
  QueryParams getParams() => <String, dynamic>{
    'page': '$page',
    'perPage': '$perPage',
  };
}
