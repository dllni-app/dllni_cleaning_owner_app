import 'package:common_package/helpers/typedef.dart';
import 'package:dio/dio.dart';

import 'error_handler.dart';

mixin HandlingApiManager {
  Future<T> wrapHandlingApi<T>({required Future<Response> Function() tryCall, required FromJson<T> jsonConvert}) async {
    final response = await tryCall();
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return jsonConvert(response.data);
    } else if (response.statusCode == 401) {
      throw UnauthenticatedFailure(message: response.data["message"].toString());
    } else if (response.statusCode == 403) {
      throw UserBlockedFailure(message: response.data["message"].toString());
    } else {
      throw ServerFailure(message: response.data["message"].toString(), statusCode: response.statusCode);
    }
  }
}
