import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'dart:convert';

@lazySingleton
class LoggerInterceptor extends Interceptor {
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 75,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  String _prettyJson(dynamic data) {
    try {
      if (data is String) {
        final decoded = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {
      return data.toString();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestPath = '${options.baseUrl}${options.path}';
    _logger.i(
      '${options.method} REQUEST => $requestPath\n'
      'Headers: ${jsonEncode(options.headers)}\n'
      'Query: ${jsonEncode(options.queryParameters)}\n'
      'Body: ${_prettyJson(options.data)}',
    );
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestPath =
        '${response.requestOptions.baseUrl}${response.requestOptions.path}';
    _logger.i(
      'RESPONSE [${response.statusCode}] => $requestPath\n'
      'Data: ${_prettyJson(response.data)}',
    );
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final requestPath = '${options.baseUrl}${options.path}';
    _logger.e(
      'ERROR => $requestPath\n'
      'Message: ${err.message}\n'
      'StatusCode: ${err.response?.statusCode}\n'
      'Response: ${_prettyJson(err.response?.data)}',
    );
    return super.onError(err, handler);
  }
}
