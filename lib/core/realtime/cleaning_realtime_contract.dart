import '../../features/orders/data/models/cleaning_booking_status.dart';

class CleaningRealtimeContract {
  CleaningRealtimeContract._();

  static const String bookingChannelPrefix = 'private-cleaning-booking.';
  static const String workerChannelPrefix = 'private-cleaning-worker.';
  static const String customerChannelPrefix = 'private-cleaning-customer.';

  static const String workerLocationUpdated = 'WorkerLocationUpdated';
  static const String workerArrived = 'WorkerArrived';
  static const String securityCodeIssued = 'SecurityCodeIssued';
  static const String securityCodeIssuedScoped =
      'cleaning_order.security_code_issued';
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
    securityCodeIssued: awaitingStartVerification,
    securityCodeIssuedScoped: awaitingStartVerification,
    'ArrivalVerificationRequested': awaitingStartVerification,
    'arrival_verification_requested': awaitingStartVerification,
    'cleaning_order.arrival_verification_requested': awaitingStartVerification,
    'worker_arrived': workerArrived,
    'cleaning_order.worker_arrived': workerArrived,
    'cleaning_order.arrival_verified': arrivalVerified,
    'arrival_verified': arrivalVerified,
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
    void addAlias(String key, String value, {bool overrideExisting = true}) {
      final trimmed = key.trim();
      if (trimmed.isEmpty) return;
      final lower = trimmed.toLowerCase();
      if (overrideExisting) {
        aliases[trimmed] = value;
        aliases[lower] = value;
        return;
      }
      aliases.putIfAbsent(trimmed, () => value);
      aliases.putIfAbsent(lower, () => value);
    }

    for (final entry in legacyEventAliases.entries) {
      addAlias(entry.key, entry.value);
    }

    const canonicalEvents = <String>{
      workerLocationUpdated,
      workerArrived,
      securityCodeIssued,
      securityCodeIssuedScoped,
      awaitingStartVerification,
      arrivalVerified,
      awaitingCustomerCompletion,
      completionDecisionMade,
      serviceExtensionRequested,
      trackingUpdated,
      teamUpdated,
    };
    for (final eventName in canonicalEvents) {
      addAlias(eventName, eventName, overrideExisting: false);
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
    final unwrapped = unwrapPayload(payload);
    final trackingMap = _asStringMap(unwrapped['tracking']);
    final bookingMap = _asStringMap(unwrapped['booking']);
    final cleaningOrderMap = _nestedBookingMap(unwrapped);
    final raw = trackingMap['status'] ??
        bookingMap['status'] ??
        cleaningOrderMap['status'] ??
        unwrapped['status'];
    if (raw == null) return null;
    final normalized = raw.toString().trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  static ({String? arrivedAt, String? workStartedAt}) extractLifecycleTimestamps(
    Map<String, dynamic> payload,
  ) {
    final unwrapped = unwrapPayload(payload);
    final sources = <Map<String, dynamic>>[
      unwrapped,
      _asStringMap(unwrapped['tracking']),
      _asStringMap(unwrapped['booking']),
      _nestedBookingMap(unwrapped),
    ];

    String? pick(String camel, String snake) {
      for (final source in sources) {
        final value = source[camel] ?? source[snake];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return null;
    }

    return (
      arrivedAt: pick('arrivedAt', 'arrived_at'),
      workStartedAt: pick('workStartedAt', 'work_started_at'),
    );
  }

  static int? extractBookingId(Map<String, dynamic> payload) {
    final unwrapped = unwrapPayload(payload);
    final trackingMap = _asStringMap(unwrapped['tracking']);
    final cleaningOrderMap = _nestedBookingMap(unwrapped);
    final orderMap = _asStringMap(unwrapped['order']);
    final bookingMap = _asStringMap(unwrapped['booking']);

    return _extractIdFromMap(trackingMap) ??
        _extractIdFromMap(cleaningOrderMap) ??
        _extractIdFromMap(orderMap) ??
        _extractIdFromMap(bookingMap) ??
        _extractIdFromMap(unwrapped) ??
        _asInt(
          unwrapped['cleaningBookingId'] ??
              unwrapped['cleaning_bookingId'] ??
              unwrapped['bookingId'] ??
              unwrapped['booking_id'] ??
              unwrapped['cleaningOrderId'] ??
              unwrapped['cleaning_order_id'] ??
              unwrapped['cleaning_booking_id'] ??
              unwrapped['id'] ??
              unwrapped['orderId'] ??
              unwrapped['order_id'],
        );
  }

  static Map<String, dynamic> _nestedBookingMap(Map<String, dynamic> source) {
    return _asStringMap(
      source['cleaningOrder'] ??
          source['cleaning_order'] ??
          source['cleaningBooking'] ??
          source['cleaning_booking'],
    );
  }

  static Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, nested) => MapEntry(key.toString(), nested));
    }
    return const <String, dynamic>{};
  }

  static int? _extractIdFromMap(Map<String, dynamic> source) {
    if (source.isEmpty) return null;
    return _asInt(
      source['id'] ??
          source['cleaningBookingId'] ??
          source['cleaning_bookingId'] ??
          source['bookingId'] ??
          source['booking_id'] ??
          source['cleaningOrderId'] ??
          source['cleaning_order_id'] ??
          source['cleaning_booking_id'] ??
          source['orderId'] ??
          source['order_id'],
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
    final unwrapped = unwrapPayload(payload);
    final latitude = _asDouble(unwrapped['latitude'] ?? unwrapped['lat']);
    final longitude = _asDouble(unwrapped['longitude'] ?? unwrapped['lng']);
    if (latitude == null || longitude == null) return null;
    final workerId = _asInt(unwrapped['workerId'] ?? unwrapped['worker_id']);
    final updatedAt = (unwrapped['updatedAt'] ?? unwrapped['updated_at'])
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
