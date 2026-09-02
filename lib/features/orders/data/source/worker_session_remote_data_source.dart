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

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
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
      securityCode:
          data['securityCode']?.toString() ?? data['security_code']?.toString(),
      expiresAt:
          data['expiresAt']?.toString() ?? data['expires_at']?.toString(),
    );
  }

  WorkerSessionSecurityCodeModel withRequestContext({
    required int bookingId,
    required int sessionId,
  }) {
    return WorkerSessionSecurityCodeModel(
      bookingId: this.bookingId ?? bookingId,
      sessionId: this.sessionId ?? sessionId,
      securityCode: securityCode,
      expiresAt: expiresAt,
    );
  }
}

class WorkerSessionAcceptanceRejection {
  final int sessionId;
  final String reasonCode;
  final String message;

  const WorkerSessionAcceptanceRejection({
    required this.sessionId,
    required this.reasonCode,
    required this.message,
  });

  factory WorkerSessionAcceptanceRejection.fromJson(dynamic json) {
    final value = _map(json);
    return WorkerSessionAcceptanceRejection(
      sessionId: _toInt(value['sessionId'] ?? value['session_id']) ?? 0,
      reasonCode:
          value['reasonCode']?.toString() ??
          value['reason_code']?.toString() ??
          'acceptance_failed',
      message:
          value['message']?.toString() ??
          'تعذر قبول هذه الجلسة. حدّث الطلب وحاول من جديد.',
    );
  }
}

class WorkerSessionAcceptanceResult {
  final bool allAccepted;
  final List<int> acceptedSessionIds;
  final List<WorkerSessionAcceptanceRejection> rejected;

  const WorkerSessionAcceptanceResult({
    required this.allAccepted,
    required this.acceptedSessionIds,
    required this.rejected,
  });

  factory WorkerSessionAcceptanceResult.fromJson(dynamic json) {
    final root = _map(json);
    final data = root['data'] is Map ? _map(root['data']) : root;
    final acceptance = data['acceptance'] is Map
        ? _map(data['acceptance'])
        : data;
    final acceptedRaw =
        acceptance['acceptedSessionIds'] ?? acceptance['accepted_session_ids'];
    final rejectedRaw = acceptance['rejected'];

    return WorkerSessionAcceptanceResult(
      allAccepted: _toBool(
        acceptance['allAccepted'] ?? acceptance['all_accepted'],
      ),
      acceptedSessionIds: acceptedRaw is List
          ? acceptedRaw.map(_toInt).whereType<int>().toList(growable: false)
          : const <int>[],
      rejected: rejectedRaw is List
          ? rejectedRaw
                .map(WorkerSessionAcceptanceRejection.fromJson)
                .toList(growable: false)
          : const <WorkerSessionAcceptanceRejection>[],
    );
  }
}

@lazySingleton
class WorkerSessionRemoteDataSource with HandlingApiManager {
  final DioNetwork dioNetwork;

  WorkerSessionRemoteDataSource({required this.dioNetwork});

  Future<WorkerMultiDayBookingEnvelope> fetchBookingSchedule(int bookingId) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(
        endPoint: '/api/v1/cleaning-bookings/$bookingId/schedule',
      ),
      jsonConvert: workerMultiDayBookingEnvelopeFromJson,
    );
  }

  Future<WorkerSessionAcceptanceResult> acceptAllSessions(int bookingId) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(
        endPoint: '/api/v1/cleaning-bookings/$bookingId/sessions/accept-all',
        data: const <String, dynamic>{},
      ),
      jsonConvert: WorkerSessionAcceptanceResult.fromJson,
    );
  }

  Future<WorkerSessionAcceptanceResult> acceptSelectedSessions({
    required int bookingId,
    required List<int> sessionIds,
  }) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.postData(
        endPoint:
            '/api/v1/cleaning-bookings/$bookingId/sessions/accept-selected',
        data: <String, dynamic>{'sessionIds': sessionIds},
      ),
      jsonConvert: WorkerSessionAcceptanceResult.fromJson,
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
      data: <String, dynamic>{'latitude': latitude, 'longitude': longitude},
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
      jsonConvert: (json) => WorkerSessionSecurityCodeModel.fromJson(
        json,
      ).withRequestContext(bookingId: bookingId, sessionId: sessionId),
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
