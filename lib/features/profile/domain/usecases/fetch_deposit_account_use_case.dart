import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fetch_deposit_account_usecase_model.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class FetchDepositAccountUseCase
    implements UseCase<FetchDepositAccountUsecaseModel, NoParams> {
  final ProfileRepo profileRepo;

  FetchDepositAccountUseCase({required this.profileRepo});

  @override
  DataResponse<FetchDepositAccountUsecaseModel> call(NoParams params) {
    return profileRepo.fetchDepositAccount(params);
  }
}
