import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/notification_api_models.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class DeleteNotificationUseCase
    implements UseCase<ActionResultModel, DeleteNotificationParams> {
  final ProfileRepo profileRepo;

  DeleteNotificationUseCase({required this.profileRepo});

  @override
  DataResponse<ActionResultModel> call(DeleteNotificationParams params) {
    return profileRepo.deleteNotification(params);
  }
}

class DeleteNotificationParams with Params {
  final String notificationId;

  DeleteNotificationParams({required this.notificationId});

  @override
  BodyMap getBody() => {};
}
