import 'package:common_package/helpers/api_handler.dart';
import 'package:common_package/helpers/dio_network.dart';
import 'package:injectable/injectable.dart';

import '../models/worker_booking_schedule_model.dart';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

class WorkerSessionSecurityCodeModel {
  final int? bookingId;
  final int? sessionId;
  final String? securityCode;
  final String? expiresAt;

  const WorkerSessionSecurityCodeModel({
    this.bookingId,
    this.sessionId,
    this.securityCode,
    this.expiresAt,
  });

  factory WorkerSessionSecurityCodeModel.fromJson(dynamic json) {
    final root = _map(json);
    final data = root['data'] is Map ? _map(root['data']) : root;
    return WorkerSessionSecurityCodeModel(
      bookingId: _toInt(data['bookingId'] ?? data['booking_id']),
      sessionId: _toInt(data['sessionId'] ?? data['session_id']),
      securityCode: data['securityCode']?.toString() ??
          data['security_code']?.toString(),
      expiresAt: data['expiresAt']?.toString() ?? data['expires_at']?.toString(),
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

@lazySingleton
class WorkerSessionRemoteDataSource with HandlingApiManager {
  final DioNetwork dioNetwork;

  WorkerSessionRemoteDataSource({required this.dioNetwork});

  Future<WorkerMultiDayBookingEnvelope> fetchBookingSchedule(int bookingId) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning-bookings/$bookingId',
      ),
      jsonConvert: workerMultiDayBookingEnvelopeFromJson,
    );
  }

  Future<WorkerMultiDayBookingEnvelope> startTravel({
    required int bookingId,
    required int sessionId,
  }) {
    return _post(
      '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/start-travel',
    );
  }

  Future<WorkerMultiDayBookingEnvelope> postLocation({
    required int bookingId,
    required int sessionId,
    required double latitude,
    required double longitude,
  }) {
    return _post(
      '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/location',
      data: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<WorkerMultiDayBookingEnvelope> arrive({
    required int bookingId,
    required int sessionId,
  }) {
    return _post(
      '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/arrive',
    );
  }

  Future<WorkerSessionSecurityCodeModel> fetchSecurityCode({
    required int bookingId,
    required int sessionId,
  }) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint:
            '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/security-code',
      ),
      jsonConvert: WorkerSessionSecurityCodeModel.fromJson,
    );
  }

  Future<WorkerMultiDayBookingEnvelope> startWork({
    required int bookingId,
    required int sessionId,
  }) {
    return _post(
      '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/start-work',
    );
  }

  Future<WorkerMultiDayBookingEnvelope> complete({
    required int bookingId,
    required int sessionId,
    String? completionMessage,
  }) {
    return _post(
      '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/complete',
      data: <String, dynamic>{
        if (completionMessage != null && completionMessage.trim().isNotEmpty)
          'completionMessage': completionMessage.trim(),
      },
    );
  }

  Future<WorkerMultiDayBookingEnvelope> cancel({
    required int bookingId,
    required int sessionId,
    required String reason,
  }) {
    return _post(
      '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/cancel',
      data: <String, dynamic>{'reason': reason.trim()},
    );
  }

  Future<WorkerMultiDayBookingEnvelope> sendSos({
    required int bookingId,
    required int sessionId,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    return _post(
      '/api/v1/cleaning-bookings/$bookingId/sessions/$sessionId/sos',
      data: data,
    );
  }

  Future<WorkerMultiDayBookingEnvelope> _post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(
        endPoint: endpoint,
        data: data ?? const <String, dynamic>{},
      ),
      jsonConvert: workerMultiDayBookingEnvelopeFromJson,
    );
  }
}
