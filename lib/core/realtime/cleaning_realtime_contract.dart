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
  static const String teamUpdated = 'cleaning_booking.team_updated';

  static const Map<String, String> legacyEventAliases = <String, String>{
    'SecurityCodeIssued': awaitingStartVerification,
    'cleaning_order.security_code_issued': awaitingStartVerification,
    'ArrivalVerificationRequested': awaitingStartVerification,
    'cleaning_order.arrival_verified': arrivalVerified,
    'CompletionReviewRequested': awaitingCustomerCompletion,
    'completion_review_requested': awaitingCustomerCompletion,
    'cleaning_order.completion_review_requested': awaitingCustomerCompletion,
    'service_extension_requested': serviceExtensionRequested,
    'cleaning_order.service_extension_requested': serviceExtensionRequested,
    'completion_decision_made': completionDecisionMade,
    'cleaning_order.completion_decision_made': completionDecisionMade,
  };

  static final Map<String, String> _normalizedEventAliases =
      _buildNormalizedEventAliases();

  static Map<String, String> _buildNormalizedEventAliases() {
    final aliases = <String, String>{};
    void addAlias(String key, String value) {
      final trimmed = key.trim();
      if (trimmed.isEmpty) return;
      aliases[trimmed] = value;
      aliases[trimmed.toLowerCase()] = value;
    }

    for (final entry in legacyEventAliases.entries) {
      addAlias(entry.key, entry.value);
    }

    const canonicalEvents = <String>{
      workerLocationUpdated,
      workerArrived,
      awaitingStartVerification,
      arrivalVerified,
      awaitingCustomerCompletion,
      completionDecisionMade,
      serviceExtensionRequested,
      trackingUpdated,
      teamUpdated,
    };
    for (final eventName in canonicalEvents) {
      addAlias(eventName, eventName);
    }
    return aliases;
  }

  static String normalizeEventName(String eventName) {
    final raw = eventName.trim();
    if (raw.isEmpty) return raw;
    return _normalizedEventAliases[raw] ??
        _normalizedEventAliases[raw.toLowerCase()] ??
        raw;
  }

  /// Expands canonical event names with known legacy / snake_case aliases for
  /// [PusherManager] filters that compare raw broadcast names.
  static Set<String> expandEventFilter(Iterable<String> canonicalEventNames) {
    final expanded = <String>{};
    for (final canonical in canonicalEventNames) {
      expanded.add(canonical);
      expanded.add(canonical.toLowerCase());
      for (final entry in legacyEventAliases.entries) {
        if (entry.value == canonical) {
          expanded.add(entry.key);
        }
      }
    }
    return expanded;
  }

  static bool matchesEventFilter(Set<String> filter, String rawEventName) {
    if (filter.contains(rawEventName)) return true;
    return filter.contains(normalizeEventName(rawEventName));
  }

  static Map<String, dynamic> unwrapPayload(Map<String, dynamic> payload) {
    final nested = _asStringMap(payload['data']);
    if (nested.isEmpty) return payload;
    return <String, dynamic>{...nested, ...payload};
  }

  static int? extractWarningId(Map<String, dynamic> payload) {
    final unwrapped = unwrapPayload(payload);
    return _asInt(unwrapped['warningId'] ?? unwrapped['warning_id']);
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
        normalized == trackingUpdated ||
        normalized == teamUpdated;
  }

  static bool shouldRefreshPendingOrdersForWorkerEvent(
    String eventName,
    Map<String, dynamic> payload,
  ) {
    if (isLifecycleRefreshEvent(eventName)) {
      return true;
    }
    final unwrapped = unwrapPayload(payload);
    return extractTrackingStatus(unwrapped) == CleaningBookingStatus.pending;
  }

  static String? extractTrackingStatus(Map<String, dynamic> payload) {
    final tracking = payload['tracking'];
    final trackingMap = tracking is Map
        ? tracking.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final raw = trackingMap['status'] ?? payload['status'];
    if (raw == null) return null;
    final normalized = raw.toString().trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  static int? extractBookingId(Map<String, dynamic> payload) {
    final unwrapped = unwrapPayload(payload);
    final tracking = unwrapped['tracking'];
    final trackingMap = tracking is Map
        ? tracking.map((k, v) => MapEntry(k.toString(), v))
        : const <String, dynamic>{};
    final bookingMap = _asStringMap(unwrapped['booking']);
    return _asInt(
          trackingMap['cleaningBookingId'] ??
              trackingMap['bookingId'] ??
              trackingMap['booking_id'] ??
              trackingMap['cleaning_booking_id'] ??
              trackingMap['id'],
        ) ??
        _asInt(
          bookingMap['id'] ??
              bookingMap['bookingId'] ??
              bookingMap['booking_id'],
        ) ??
        _asInt(
          unwrapped['cleaningBookingId'] ??
              unwrapped['bookingId'] ??
              unwrapped['booking_id'] ??
              unwrapped['cleaning_booking_id'] ??
              unwrapped['id'] ??
              unwrapped['orderId'] ??
              unwrapped['order_id'],
        );
  }

  static Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is! Map) return const <String, dynamic>{};
    return value.map((key, nested) => MapEntry(key.toString(), nested));
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
