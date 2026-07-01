import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@lazySingleton
class LoggerInterceptor extends Interceptor {
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options,
      RequestInterceptorHandler handler,) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    _logger.i(
      '🚀 ${options.method} ${options.uri}\n'
          '${options.data ?? ''}',
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response,
      ResponseInterceptorHandler handler,) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    _logger.i(
      '✅ ${response.statusCode} ${response.requestOptions.method} ${response
          .requestOptions.path}\n'
          '${response.data}',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err,
      ErrorInterceptorHandler handler,) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;

    String requestBody = '';
    if (request.data != null) {
      requestBody = request.data.toString();
    }

    String responseBody = '';
    if (err.response?.data != null) {
      responseBody = err.response!.data.toString();
    }

    _logger.e(
      '❌ ${err.response?.statusCode ?? 'UNKNOWN'} '
          '${request.method} '
          '${request.uri}\n\n'
          'Message:\n'
          '${err.message}\n\n'
          'Type:\n'
          '${err.type}\n\n'
          'Headers:\n'
          '${request.headers}\n\n'
          'Query Parameters:\n'
          '${request.queryParameters}\n\n'
          '${requestBody.isNotEmpty ? 'Request Body:\n$requestBody\n\n' : ''}'
          '${responseBody.isNotEmpty
          ? 'Response Body:\n$responseBody\n\n'
          : ''}'
          'StackTrace:\n'
          '${err.stackTrace}',
    );

    handler.next(err);
  }
}