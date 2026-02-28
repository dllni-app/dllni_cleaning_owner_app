import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/home_repo.dart';
import '../../data/models/fetch_home_page_usecase_model.dart';

@lazySingleton
class FetchHomePageUsecaseUseCase implements UseCase<FetchHomePageUsecaseModel, FetchHomePageUsecaseParams> {

  final HomeRepo home;

  FetchHomePageUsecaseUseCase({required this.home});

  @override
  DataResponse<FetchHomePageUsecaseModel> call(FetchHomePageUsecaseParams params) {
    return home.fetchHomePageUsecase(params);
  }
}

class FetchHomePageUsecaseParams with Params{}
