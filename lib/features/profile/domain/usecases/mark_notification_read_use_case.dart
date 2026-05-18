import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/notification_api_models.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class MarkNotificationReadUseCase implements UseCase<ActionResultModel, MarkNotificationReadParams> {
  final ProfileRepo profileRepo;

  MarkNotificationReadUseCase({required this.profileRepo});

  @override
  DataResponse<ActionResultModel> call(MarkNotificationReadParams params) {
    return profileRepo.markNotificationRead(params);
  }
}

class MarkNotificationReadParams with Params {
  final String notificationId;

  MarkNotificationReadParams({required this.notificationId});
}
