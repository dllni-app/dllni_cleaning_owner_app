import '../../features/orders/data/models/cleaning_booking_status.dart';

class CleaningRealtimeContract {
  CleaningRealtimeContract._();

  static const String bookingChannelPrefix = 'private-cleaning-booking.';
  static const String workerChannelPrefix = 'private-cleaning-worker.';
  static const String customerChannelPrefix = 'private-cleaning-customer.';

  static const String workerLocationUpdated = 'WorkerLocationUpdated';
  static const String workerArrived = 'WorkerArrived';
  static const String awaitingStartVerification =
      'cleaning_order.awaiting_start_verification';
  static const String arrivalVerified = 'ArrivalVerified';
  static const String awaitingCustomerCompletion =
      'cleaning_order.awaiting_customer_completion';
  static const String completionDecisionMade = 'CompletionDecisionMade';
  static const String serviceExtensionRequested = 'ServiceExtensionRequested';
  static const String trackingUpdated = 'CleaningBookingTrackingUpdated';

  static const Map<String, String> legacyEventAliases = <String, String>{
    'SecurityCodeIssued': awaitingStartVerification,
    'cleaning_order.security_code_issued': awaitingStartVerification,
    'ArrivalVerificationRequested': awaitingStartVerification,
    'CompletionReviewRequested': awaitingCustomerCompletion,
  };

  static String normalizeEventName(String eventName) {
    return legacyEventAliases[eventName] ?? eventName;
  }

  static bool isLocationEvent(String eventName) {
    return normalizeEventName(eventName) == workerLocationUpdated;
  }

  static bool isLifecycleRefreshEvent(String eventName) {
    final normalized = normalizeEventName(eventName);
    return normalized == workerArrived ||
        normalized == awaitingStartVerification ||
        normalized == arrivalVerified ||
        normalized == awaitingCustomerCompletion ||
        normalized == completionDecisionMade ||
        normalized == serviceExtensionRequested ||
        normalized == trackingUpdated;
  }

  static int? extractBookingId(Map<String, dynamic> payload) {
    final tracking = payload['tracking'];
    final trackingMap = tracking is Map
        ? tracking.map((k, v) => MapEntry(k.toString(), v))
        : const <String, dynamic>{};
    return _asInt(
          trackingMap['cleaningBookingId'] ??
              trackingMap['bookingId'] ??
              trackingMap['booking_id'] ??
              trackingMap['cleaning_booking_id'] ??
              trackingMap['id'],
        ) ??
        _asInt(
          payload['cleaningBookingId'] ??
              payload['bookingId'] ??
              payload['booking_id'] ??
              payload['cleaning_booking_id'] ??
              payload['id'] ??
              payload['orderId'] ??
              payload['order_id'],
        );
  }

  static String? statusFromDecision(String? decision) {
    final normalized = (decision ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'approved':
        return CleaningBookingStatus.completed;
      case 'rejected':
        return CleaningBookingStatus.inProgress;
      case 'extension_requested':
        return CleaningBookingStatus.timeExtensionRequested;
      default:
        return null;
    }
  }

  static CleaningRealtimeLocation? parseLocation(Map<String, dynamic> payload) {
    final latitude = _asDouble(payload['latitude'] ?? payload['lat']);
    final longitude = _asDouble(payload['longitude'] ?? payload['lng']);
    if (latitude == null || longitude == null) return null;
    final workerId = _asInt(payload['workerId'] ?? payload['worker_id']);
    final updatedAt = (payload['updatedAt'] ?? payload['updated_at'])
        ?.toString();
    return CleaningRealtimeLocation(
      latitude: latitude,
      longitude: longitude,
      workerId: workerId,
      updatedAt: updatedAt,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

class CleaningRealtimeLocation {
  const CleaningRealtimeLocation({
    required this.latitude,
    required this.longitude,
    this.workerId,
    this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final int? workerId;
  final String? updatedAt;
}
