import 'package:dio/dio.dart';
import 'package:common_package/common_package.dart';

import '../app_config.dart';

class LocationReporter {
  const LocationReporter._();

  static const String _tokenKey = 'token';

  static Future<void> postLocation({
    required int bookingId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await SharedPreferencesHelper.init();
      final token = (SharedPreferencesHelper.getData(key: _tokenKey) ?? '')
          .toString()
          .trim();
      if (token.isEmpty) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          headers: <String, String>{
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      await dio.post(
        '/api/v1/cleaning-bookings/$bookingId/location',
        data: <String, double>{'latitude': latitude, 'longitude': longitude},
      );
    } catch (_) {
      // Ignore background reporting failures to keep tracking loop alive.
    }
  }
}
