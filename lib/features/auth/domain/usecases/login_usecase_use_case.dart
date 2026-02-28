import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/auth_repo.dart';
import '../../data/models/login_usecase_model.dart';

@lazySingleton
class LoginUsecaseUseCase implements UseCase<LoginUsecaseModel, LoginUsecaseParams> {
  final AuthRepo auth;

  LoginUsecaseUseCase({required this.auth});

  @override
  DataResponse<LoginUsecaseModel> call(LoginUsecaseParams params) {
    return auth.loginUsecase(params);
  }
}

class LoginUsecaseParams with Params {
  final String email;
  final String password;

  LoginUsecaseParams({required this.email, required this.password});

  @override
  BodyMap getBody() => {'phone': email, 'password': password};
}
