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

    _logger.i(
      '🚀 ${options.method} ${options.uri.toString()}',
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

    // تحويل الـ Body لـ 5 أسطر
    String bodyPreview = data.toString();
    List<String> lines = bodyPreview.split('\n');
    if (lines.length > 5) {
      bodyPreview = lines.take(5).join('\n') + '\n... (truncated)';
    }

    // استخدم response.requestOptions.uri.toString() للرابط الكامل
    _logger.i(
      '✅ ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri.toString()}'
          '${summary.isNotEmpty ? ' ($summary)' : ''}\n'
          'Body: $bodyPreview',
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

    _logger.e(
      '❌ ${err.response?.statusCode ?? 'UNKNOWN'} '
          '${err.requestOptions.method} '
          '${err.requestOptions.path}\n'
          '${err.message}',
    );

    handler.next(err);
  }
}