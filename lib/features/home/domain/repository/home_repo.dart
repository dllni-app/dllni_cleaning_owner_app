import 'package:common_package/helpers/typedef.dart';
import '../usecases/fetch_home_page_usecase_use_case.dart';
import '../../data/models/fetch_home_page_usecase_model.dart';
abstract class HomeRepo {
  DataResponse<FetchHomePageUsecaseModel> fetchHomePageUsecase(FetchHomePageUsecaseParams params);
}
