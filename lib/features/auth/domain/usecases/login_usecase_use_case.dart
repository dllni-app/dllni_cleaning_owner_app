import 'package:injectable/injectable.dart';
import 'package:common_package/common_package.dart';

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
  static const String fcmTokenPrefsKey = 'fcm';

  final String phone;
  final String password;

  LoginUsecaseParams({required this.phone, required this.password});

  @override
  BodyMap getBody() {
    final body = <String, dynamic>{
      'phone': phone,
      'password': password,
      'module': 'cleaning',
    };
    final fcmToken = _readStoredFcmToken();
    if (fcmToken != null) {
      body['fcmToken'] = fcmToken;
    }
    return body;
  }

  static String? _readStoredFcmToken() {
    final raw = SharedPreferencesHelper.getData(key: fcmTokenPrefsKey);
    if (raw == null) return null;
    final token = raw.toString().trim();
    return token.isEmpty ? null : token;
  }
}
