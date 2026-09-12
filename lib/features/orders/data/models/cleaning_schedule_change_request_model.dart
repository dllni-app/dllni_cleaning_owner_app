Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class CleaningScheduleChangeSession {
  const CleaningScheduleChangeSession({
    required this.date,
    required this.time,
    this.hours,
  });

  final String date;
  final String time;
  final double? hours;

  factory CleaningScheduleChangeSession.fromJson(Map<String, dynamic> json) {
    return CleaningScheduleChangeSession(
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      hours: json['hours'] == null ? null : _asDouble(json['hours']),
    );
  }
}

class CleaningScheduleChangeRequestModel {
  const CleaningScheduleChangeRequestModel({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.priceDelta,
    required this.sessions,
    this.createdAt,
  });

  final int id;
  final int bookingId;
  final String status;
  final double priceDelta;
  final List<CleaningScheduleChangeSession> sessions;
  final String? createdAt;

  factory CleaningScheduleChangeRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final booking = _asMap(json['booking']);
    final proposed = _asMap(
      json['proposedSnapshot'] ?? json['proposed_snapshot'],
    );
    final rawSessions = proposed['sessions'];
    return CleaningScheduleChangeRequestModel(
      id: _asInt(json['id']) ?? 0,
      bookingId:
          _asInt(json['bookingId'] ?? json['cleaning_booking_id']) ??
          _asInt(booking['id']) ??
          0,
      status: (json['status'] ?? '').toString(),
      priceDelta: _asDouble(json['priceDelta'] ?? json['price_delta']),
      sessions: rawSessions is List
          ? rawSessions
                .map(
                  (item) =>
                      CleaningScheduleChangeSession.fromJson(_asMap(item)),
                )
                .where((item) => item.date.isNotEmpty && item.time.isNotEmpty)
                .toList(growable: false)
          : const <CleaningScheduleChangeSession>[],
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
    );
  }
}

List<CleaningScheduleChangeRequestModel>
cleaningScheduleChangeRequestsEnvelopeFromJson(dynamic json) {
  final root = _asMap(json);
  final data = _asMap(root['data']);
  final raw = data['changeRequests'] ?? data['change_requests'] ?? const [];
  if (raw is! List) return const <CleaningScheduleChangeRequestModel>[];
  return raw
      .map((item) => CleaningScheduleChangeRequestModel.fromJson(_asMap(item)))
      .where((item) => item.id > 0 && item.bookingId > 0)
      .toList(growable: false);
}

CleaningScheduleChangeRequestModel
cleaningScheduleChangeRequestEnvelopeFromJson(dynamic json) {
  final root = _asMap(json);
  final data = _asMap(root['data']);
  return CleaningScheduleChangeRequestModel.fromJson(
    _asMap(data['changeRequest'] ?? data['change_request'] ?? data),
  );
}
