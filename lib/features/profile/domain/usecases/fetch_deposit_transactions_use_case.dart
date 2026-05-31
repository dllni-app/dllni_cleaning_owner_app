import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/fetch_deposit_transactions_usecase_model.dart';
import '../repository/profile_repo.dart';

@lazySingleton
class FetchDepositTransactionsUseCase
    implements
        UseCase<
          FetchDepositTransactionsUsecaseModel,
          FetchDepositTransactionsParams
        > {
  final ProfileRepo profileRepo;

  FetchDepositTransactionsUseCase({required this.profileRepo});

  @override
  DataResponse<FetchDepositTransactionsUsecaseModel> call(
    FetchDepositTransactionsParams params,
  ) {
    return profileRepo.fetchDepositTransactions(params);
  }
}

class FetchDepositTransactionsParams with Params {
  final int page;
  final int perPage;
  final String? type;

  FetchDepositTransactionsParams({this.page = 1, this.perPage = 20, this.type});

  @override
  QueryParams getParams() =>
      <String, dynamic>{'page': '$page', 'perPage': '$perPage', 'type': type}
        ..removeWhere((key, value) => value == null);
}
