import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fetch_worker_profile_usecase_model.dart';
import '../../data/models/worker_working_hours_model.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class UpdateWorkerWorkingHoursUseCase
    implements UseCase<WorkerWorkingHoursModel, UpdateWorkerWorkingHoursParams> {
  final ProfileRepo profile;

  UpdateWorkerWorkingHoursUseCase({required this.profile});

  @override
  DataResponse<WorkerWorkingHoursModel> call(UpdateWorkerWorkingHoursParams params) {
    return profile.updateWorkerWorkingHours(params);
  }
}

class UpdateWorkerWorkingHoursParams with Params {
  UpdateWorkerWorkingHoursParams({required this.defaultWorkingHours});

  final FetchWorkerProfileUsecaseModelDataDefaultWorkingHours defaultWorkingHours;

  @override
  BodyMap getBody() => {
        'defaultWorkingHours': defaultWorkingHours.toJson(),
      };
}
