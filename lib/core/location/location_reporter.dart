import 'dart:developer';

import 'package:common_package/common_package.dart';
import 'package:dio/dio.dart';

import '../app_config.dart';

class LocationReporter {
  const LocationReporter._();

  static const String _tokenKey = 'token';

  static Future<void> postLocation({
    required int bookingId,
    int? sessionId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await SharedPreferencesHelper.init();
      final token = (SharedPreferencesHelper.getData(key: _tokenKey) ?? '')
          .toString()
          .trim();
      if (token.isEmpty) {
        log('Skipping cleaning location report: missing auth token.');
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          headers: <String, String>{
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final endpoint = sessionId != null && sessionId > 0
          ? '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/location'
          : '/api/v1/cleaning-bookings/$bookingId/location';
      final response = await dio.post(
        endpoint,
        data: <String, double>{'latitude': latitude, 'longitude': longitude},
      );

      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final ignored = data is Map && data['ignored'] == true;
      if (ignored) {
        log(
          'Cleaning location report ignored by lifecycle policy '
          '(bookingId=$bookingId, sessionId=$sessionId, statusCode=${response.statusCode}).',
        );
      }
    } catch (error, stackTrace) {
      log(
        'Cleaning location report failed '
        '(bookingId=$bookingId, sessionId=$sessionId): $error',
        stackTrace: stackTrace,
      );
    }
  }
}
