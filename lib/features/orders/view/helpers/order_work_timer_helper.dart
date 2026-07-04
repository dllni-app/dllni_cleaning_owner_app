class OrderWorkTimerSession {
  const OrderWorkTimerSession({
    required this.sessionStart,
    required this.maxDuration,
    required this.sessionKey,
    required this.isExtension,
  });

  final DateTime sessionStart;
  final Duration maxDuration;
  final String sessionKey;
  final bool isExtension;

  Duration elapsedAt(DateTime now) {
    final elapsed = now.difference(sessionStart);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  bool isFinishedAt(DateTime now) => elapsedAt(now) >= maxDuration;
}

class AcceptedExtensionTimerSeed {
  const AcceptedExtensionTimerSeed({
    required this.id,
    required this.minutes,
  });

  final int? id;
  final int minutes;

  String get sessionKey => 'extension:${id ?? 'unknown'}:$minutes';
}

class OrderWorkTimerHelper {
  const OrderWorkTimerHelper._();

  static Duration? originalBookingDuration({
    required double? totalHours,
    required double? estimatedHours,
  }) {
    return durationFromHours(
      totalHours != null && totalHours > 0 ? totalHours : estimatedHours,
    );
  }

  static OrderWorkTimerSession startOriginalSession({
    required DateTime now,
    required Duration maxDuration,
  }) {
    return OrderWorkTimerSession(
      sessionStart: now,
      maxDuration: maxDuration,
      sessionKey: 'base:${now.microsecondsSinceEpoch}:${maxDuration.inSeconds}',
      isExtension: false,
    );
  }

  static OrderWorkTimerSession startExtensionSession({
    required DateTime now,
    required AcceptedExtensionTimerSeed seed,
  }) {
    return OrderWorkTimerSession(
      sessionStart: now,
      maxDuration: Duration(minutes: seed.minutes),
      sessionKey: seed.sessionKey,
      isExtension: true,
    );
  }

  static int totalAcceptedExtensionMinutes(List<dynamic>? warnings) {
    if (warnings == null) return 0;
    var total = 0;
    for (final warning in warnings) {
      final map = _asStringMap(warning);
      if (map.isEmpty || !_isAccepted(map)) continue;
      final minutes = _asInt(
        _pick(map, const <String>[
          'approvedMinutes',
          'approved_minutes',
          'additionalMinutes',
          'additional_minutes',
          'requestedMinutes',
          'requested_minutes',
          'minutes',
        ]),
      );
      if (minutes != null && minutes > 0) total += minutes;
    }
    return total;
  }

  static AcceptedExtensionTimerSeed? latestAcceptedExtensionSeed(
    List<dynamic>? warnings,
  ) {
    if (warnings == null || warnings.isEmpty) return null;

    AcceptedExtensionTimerSeed? latest;
    DateTime? latestTime;
    for (final warning in warnings) {
      final map = _asStringMap(warning);
      if (map.isEmpty || !_isAccepted(map)) continue;

      final minutes = _asInt(
        _pick(map, const <String>[
          'approvedMinutes',
          'approved_minutes',
          'additionalMinutes',
          'additional_minutes',
          'requestedMinutes',
          'requested_minutes',
          'minutes',
        ]),
      );
      if (minutes == null || minutes <= 0) continue;

      final responseTime = _parseDateTime(
        _asString(
          _pick(map, const <String>[
            'workerRespondedAt',
            'worker_responded_at',
            'respondedAt',
            'responded_at',
            'acceptedAt',
            'accepted_at',
            'updatedAt',
            'updated_at',
            'createdAt',
            'created_at',
          ]),
        ),
      );
      final id = _asInt(_pick(map, const <String>['id', 'warningId', 'warning_id']));
      final candidate = AcceptedExtensionTimerSeed(id: id, minutes: minutes);
      if (latest == null ||
          (responseTime != null &&
              (latestTime == null || responseTime.isAfter(latestTime))) ||
          (responseTime == null && id != null && (latest.id == null || id > latest.id!))) {
        latest = candidate;
        latestTime = responseTime;
      }
    }
    return latest;
  }

  static Duration? durationFromHours(double? hours) {
    if (hours == null || hours <= 0) return null;
    return Duration(minutes: (hours * 60).round());
  }

  static DateTime? _parseDateTime(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static bool _isAccepted(Map<String, dynamic> map) {
    final workerResponse = _asString(
      _pick(map, const <String>['workerResponse', 'worker_response']),
    )?.trim().toLowerCase();
    if (workerResponse == 'accept' || workerResponse == 'accepted') return true;

    final responseStatus = _asString(
      _pick(map, const <String>[
        'responseStatus',
        'response_status',
        'status',
      ]),
    )?.trim().toLowerCase();
    return responseStatus == 'accept' || responseStatus == 'accepted';
  }

  static Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, nestedValue) => MapEntry(key.toString(), nestedValue));
    }
    return const <String, dynamic>{};
  }

  static dynamic _pick(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      final value = map[key];
      if (value != null) return value;
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ??
        double.tryParse(value?.toString() ?? '')?.toInt();
  }
}
