import 'package:common_package/helpers/typedef.dart';
import '../usecases/login_usecase_use_case.dart';
import '../../data/models/login_usecase_model.dart';
abstract class AuthRepo {
  DataResponse<LoginUsecaseModel> loginUsecase(LoginUsecaseParams params);
}
