class OrderWorkTimerSession {
  const OrderWorkTimerSession({
    required this.startedAt,
    required this.duration,
    required this.sessionKey,
    required this.isOvertime,
  });

  final DateTime startedAt;
  final Duration duration;
  final String sessionKey;
  final bool isOvertime;

  DateTime get expectedFinishAt => startedAt.add(duration);
}

class OrderWorkTimerHelper {
  const OrderWorkTimerHelper._();

  static OrderWorkTimerSession? resolve({
    required String? scheduledDate,
    required String? scheduledTime,
    required String? workStartedAt,
    required String? arrivedAt,
    required double? totalHours,
    required double? estimatedHours,
    required List<dynamic>? timeWarnings,
  }) {
    final acceptedOvertime = _latestAcceptedOvertime(timeWarnings);
    if (acceptedOvertime != null) {
      return OrderWorkTimerSession(
        startedAt: acceptedOvertime.acceptedAt,
        duration: Duration(minutes: acceptedOvertime.minutes),
        sessionKey:
            'extension:${acceptedOvertime.id ?? 'unknown'}:${acceptedOvertime.acceptedAt.toIso8601String()}:${acceptedOvertime.minutes}',
        isOvertime: true,
      );
    }

    final actualStart = parseDateTime(workStartedAt) ?? parseDateTime(arrivedAt);
    if (actualStart == null) return null;

    final scheduledStart = parseScheduledDateTime(scheduledDate, scheduledTime);
    final effectiveStart = scheduledStart != null && actualStart.isBefore(scheduledStart)
        ? scheduledStart
        : actualStart;
    final duration = durationFromHours(
      totalHours != null && totalHours > 0 ? totalHours : estimatedHours,
    );
    if (duration == null) return null;

    return OrderWorkTimerSession(
      startedAt: effectiveStart,
      duration: duration,
      sessionKey: 'base:${effectiveStart.toIso8601String()}:${duration.inMinutes}',
      isOvertime: false,
    );
  }

  static DateTime? parseDateTime(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static DateTime? parseScheduledDateTime(String? scheduledDate, String? scheduledTime) {
    final date = scheduledDate?.trim();
    if (date == null || date.isEmpty) return null;
    final time = scheduledTime?.trim();
    if (time == null || time.isEmpty) return DateTime.tryParse(date);
    return DateTime.tryParse('$date $time') ?? DateTime.tryParse('${date}T$time');
  }

  static Duration? durationFromHours(double? hours) {
    if (hours == null || hours <= 0) return null;
    return Duration(minutes: (hours * 60).round());
  }

  static _AcceptedOvertime? _latestAcceptedOvertime(List<dynamic>? warnings) {
    if (warnings == null || warnings.isEmpty) return null;

    _AcceptedOvertime? latest;
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

      final acceptedAt = parseDateTime(
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
          ]),
        ),
      );
      if (acceptedAt == null) continue;

      final candidate = _AcceptedOvertime(
        id: _asInt(_pick(map, const <String>['id', 'warningId', 'warning_id'])),
        minutes: minutes,
        acceptedAt: acceptedAt,
      );
      if (latest == null || candidate.acceptedAt.isAfter(latest.acceptedAt)) {
        latest = candidate;
      }
    }
    return latest;
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

class _AcceptedOvertime {
  const _AcceptedOvertime({
    required this.id,
    required this.minutes,
    required this.acceptedAt,
  });

  final int? id;
  final int minutes;
  final DateTime acceptedAt;
}
