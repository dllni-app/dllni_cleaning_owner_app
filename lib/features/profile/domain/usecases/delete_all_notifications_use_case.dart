import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/notification_api_models.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class DeleteAllNotificationsUseCase
    implements UseCase<ActionResultModel, NoParams> {
  final ProfileRepo profileRepo;

  DeleteAllNotificationsUseCase({required this.profileRepo});

  @override
  DataResponse<ActionResultModel> call(NoParams params) {
    return profileRepo.deleteAllNotifications(params);
  }
}
