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
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    String body = '';

    if (options.data != null) {
      body = options.data.toString();

      if (body.length > 1500) {
        body = '${body.substring(0, 1500)} ... (truncated)';
      }
    }

    _logger.i(
      '🚀 ${options.method} ${options.uri}\n'
          'Headers: ${options.headers}\n'
          '${body.isNotEmpty ? 'Body:\n$body' : ''}',
    );

    handler.next(options);
  }
  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    final data = response.data;

    String summary = '';

    if (data is List) {
      summary = 'items=${data.length}';
    } else if (data is Map<String, dynamic>) {
      summary = data.containsKey('data') && data['data'] is List
          ? 'items=${(data['data'] as List).length}'
          : 'keys=${data.keys.length}';
    }

    String body = data.toString();

    if (body.length > 2000) {
      body = '${body.substring(0, 2000)} ... (truncated)';
    }

    _logger.i(
      '✅ ${response.statusCode} '
          '${response.requestOptions.method} '
          '${response.requestOptions.uri}'
          '${summary.isNotEmpty ? ' ($summary)' : ''}\n'
          'Response:\n$body',
    );

    handler.next(response);
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) {
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
          '${responseBody.isNotEmpty ? 'Response Body:\n$responseBody\n\n' : ''}'
          'StackTrace:\n'
          '${err.stackTrace}',
    );

    handler.next(err);
  }
}