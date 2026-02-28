import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/error_handler.dart';

import '../../domain/repository/auth_repo.dart';
import 'package:common_package/helpers/typedef.dart';
import '../source/auth_remote_data_source.dart';
import '../../domain/usecases/login_usecase_use_case.dart';
import '../models/login_usecase_model.dart';

@LazySingleton(as: AuthRepo)
class AuthRepoImpl with HandlingException implements AuthRepo {
  final AuthRemoteDataSource authRemoteDataSource;

  AuthRepoImpl({required this.authRemoteDataSource});

  @override
  DataResponse<LoginUsecaseModel> loginUsecase(LoginUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => authRemoteDataSource.loginUsecase(params),
    );
  }}

