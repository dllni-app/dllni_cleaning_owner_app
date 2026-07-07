import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/worker_working_hours_model.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class FetchWorkerWorkingHoursUseCase
    implements UseCase<WorkerWorkingHoursModel, NoParams> {
  final ProfileRepo profile;

  FetchWorkerWorkingHoursUseCase({required this.profile});

  @override
  DataResponse<WorkerWorkingHoursModel> call(NoParams params) {
    return profile.fetchWorkerWorkingHours(params);
  }
}
