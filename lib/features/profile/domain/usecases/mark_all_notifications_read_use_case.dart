import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/notification_api_models.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class MarkAllNotificationsReadUseCase implements UseCase<ActionResultModel, NoParams> {
  final ProfileRepo profileRepo;

  MarkAllNotificationsReadUseCase({required this.profileRepo});

  @override
  DataResponse<ActionResultModel> call(NoParams params) {
    return profileRepo.markAllNotificationsRead(params);
  }
}
