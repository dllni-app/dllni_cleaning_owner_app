import 'package:common_package/helpers/dio_network.dart';
import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/api_handler.dart';
import '../models/login_usecase_model.dart';
import '../../domain/usecases/login_usecase_use_case.dart';

@lazySingleton
class AuthRemoteDataSource with HandlingApiManager {
  final DioNetwork dioNetwork;

  AuthRemoteDataSource({required this.dioNetwork});

  Future<LoginUsecaseModel> loginUsecase(LoginUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(endPoint: '/api/login', data: params.getBody(), params: params.getParams()),
      jsonConvert: loginUsecaseModelFromJson,
    );
  }}