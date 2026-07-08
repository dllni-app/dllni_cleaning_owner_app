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
  static const String awaitingWorkerStartConfirmation =
      'cleaning_order.awaiting_worker_start_confirmation';
  static const String awaitingCustomerCompletion =
      'cleaning_order.awaiting_customer_completion';
  static const String completionDecisionMade = 'CompletionDecisionMade';
  static const String serviceExtensionRequested = 'ServiceExtensionRequested';
  static const String trackingUpdated = 'CleaningBookingTrackingUpdated';
  static const String teamUpdated = 'cleaning_booking.team_updated';
  static const String bookingCreated = 'CleaningBookingCreated';

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
    'awaiting_worker_start_confirmation': awaitingWorkerStartConfirmation,
    'CompletionReviewRequested': awaitingCustomerCompletion,
    'completion_review_requested': awaitingCustomerCompletion,
    'cleaning_order.completion_review_requested': awaitingCustomerCompletion,
    'service_extension_requested': serviceExtensionRequested,
    'cleaning_order.service_extension_requested': serviceExtensionRequested,
    'completion_decision_made': completionDecisionMade,
    'cleaning_order.completion_decision_made': completionDecisionMade,
    'NewCleaningBooking': bookingCreated,
    'new_cleaning_booking': bookingCreated,
    'cleaning_booking.created': bookingCreated,
    'cleaning_order.created': bookingCreated,
    'new_order': bookingCreated,
  };

  static final Map<String, String> _normalizedEventAliases =
      _buildNormalizedEventAliases();

  static Map<String, String> _buildNormalizedEventAliases() {
    final aliases = <String, String>{};
    void addAlias(String key, String value, {bool overrideExisting = true}) {
      final keys = <String>{
        key.trim(),
        _canonicalEventKey(key),
      }..removeWhere((item) => item.isEmpty);

      for (final eventKey in keys) {
        final lower = eventKey.toLowerCase();
        if (overrideExisting) {
          aliases[eventKey] = value;
          aliases[lower] = value;
          continue;
        }
        aliases.putIfAbsent(eventKey, () => value);
        aliases.putIfAbsent(lower, () => value);
      }
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
      awaitingWorkerStartConfirmation,
      awaitingCustomerCompletion,
      completionDecisionMade,
      serviceExtensionRequested,
      trackingUpdated,
      teamUpdated,
      bookingCreated,
    };
    for (final eventName in canonicalEvents) {
      addAlias(eventName, eventName, overrideExisting: false);
    }
    return aliases;
  }

  static String normalizeEventName(String eventName) {
    final raw = _canonicalEventKey(eventName);
    if (raw.isEmpty) return raw;
    return _normalizedEventAliases[raw] ??
        _normalizedEventAliases[raw.toLowerCase()] ??
        raw;
  }

  static String _canonicalEventKey(String eventName) {
    var raw = eventName.trim();
    while (raw.startsWith('.')) {
      raw = raw.substring(1).trimLeft();
    }
    if (raw.isEmpty) return raw;

    // Raw Pusher payloads can expose Laravel FQCN events when broadcastAs is
    // not used, e.g. Modules\\Cleaning\\Events\\CleaningBookingCreated.
    if (raw.contains('\\')) {
      raw = raw.split('\\').last.trim();
    }

    return raw;
  }

  static Set<String> expandEventFilter(Iterable<String> canonicalEventNames) {
    final expanded = <String>{};
    for (final canonical in canonicalEventNames) {
      expanded.add(canonical);
      expanded.add(canonical.toLowerCase());
      for (final entry in legacyEventAliases.entries) {
        if (entry.value == canonical) {
          expanded.add(entry.key);
          expanded.add(_canonicalEventKey(entry.key));
        }
      }
    }
    return expanded;
  }

  static bool matchesEventFilter(Set<String> filter, String rawEventName) {
    if (filter.contains(rawEventName)) return true;
    final normalized = normalizeEventName(rawEventName);
    return filter.contains(normalized) || filter.contains(normalized.toLowerCase());
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
        normalized == awaitingWorkerStartConfirmation ||
        normalized == awaitingCustomerCompletion ||
        normalized == completionDecisionMade ||
        normalized == serviceExtensionRequested ||
        normalized == trackingUpdated ||
        normalized == teamUpdated ||
        normalized == bookingCreated;
  }

  static bool shouldRefreshPendingOrdersForWorkerEvent(
    String eventName,
    Map<String, dynamic> payload,
  ) {
    final normalized = normalizeEventName(eventName);
    if (normalized == bookingCreated) return true;
    if (isLifecycleRefreshEvent(normalized)) {
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

  static String? extractDecision(Map<String, dynamic> payload) {
    final unwrapped = unwrapPayload(payload);
    final raw = unwrapped['decision'] ??
        unwrapped['customerDecision'] ??
        unwrapped['customer_decision'];
    final text = raw?.toString().trim().toLowerCase();
    return text == null || text.isEmpty ? null : text;
  }

  static String? extractDecisionMessage(Map<String, dynamic> payload) {
    final unwrapped = unwrapPayload(payload);
    final booking = _nestedBookingMap(unwrapped);
    final raw = unwrapped['message'] ??
        unwrapped['completionMessage'] ??
        unwrapped['completion_message'] ??
        unwrapped['customerCompletionRejectionMessage'] ??
        unwrapped['customer_completion_rejection_message'] ??
        booking['message'] ??
        booking['completionMessage'] ??
        booking['completion_message'];
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? extractCompletionMessage(Map<String, dynamic> payload) {
    final unwrapped = unwrapPayload(payload);
    final booking = _nestedBookingMap(unwrapped);
    final raw = unwrapped['completionMessage'] ??
        unwrapped['completion_message'] ??
        booking['completionMessage'] ??
        booking['completion_message'] ??
        booking['workerCompletionMessage'] ??
        booking['worker_completion_message'];
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? extractCompletionExpiresAt(Map<String, dynamic> payload) {
    final unwrapped = unwrapPayload(payload);
    final raw = unwrapped['expiresAt'] ?? unwrapped['expires_at'];
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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
              unwrapped['order_id'],
        );
  }

  static Map<String, dynamic> _nestedBookingMap(Map<String, dynamic> payload) {
    final cleaningOrder = _asStringMap(payload['cleaningOrder']);
    if (cleaningOrder.isNotEmpty) return cleaningOrder;
    return _asStringMap(payload['cleaning_order']);
  }

  static int? _extractIdFromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return null;
    return _asInt(
      map['id'] ??
          map['bookingId'] ??
          map['booking_id'] ??
          map['cleaningBookingId'] ??
          map['cleaning_booking_id'] ??
          map['cleaningOrderId'] ??
          map['cleaning_order_id'],
    );
  }

  static Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
