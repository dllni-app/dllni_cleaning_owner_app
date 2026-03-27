import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/profile_repo.dart';
import '../../data/models/fetch_worker_statistics_model.dart';

@lazySingleton
class FetchWorkerStatisticsUseCase implements UseCase<FetchWorkerStatisticsModel, FetchWorkerStatisticsParams> {

  final ProfileRepo profile;

  FetchWorkerStatisticsUseCase({required this.profile});

  @override
  DataResponse<FetchWorkerStatisticsModel> call(FetchWorkerStatisticsParams params) {
    return profile.fetchWorkerStatistics(params);
  }
}

class FetchWorkerStatisticsParams with Params{}
