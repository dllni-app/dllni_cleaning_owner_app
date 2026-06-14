Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value.map((item) => _toMap(item)).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _toStringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

FetchSosAlertsModel fetchSosAlertsModelFromJson(dynamic json) {
  return FetchSosAlertsModel.fromJson(_toMap(json));
}

CleaningSosAlertModel cleaningSosAlertModelFromJson(dynamic json) {
  return CleaningSosAlertModel.fromJson(_toMap(json));
}

SosAlertModel sosAlertModelFromJson(dynamic json) {
  final map = _toMap(json);
  if (map.containsKey('data')) {
    return SosAlertModel.fromJson(_toMap(map['data']));
  }
  return SosAlertModel.fromJson(map);
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

class CleaningSosAlertModel {
  final int? id;
  final int? bookingId;
  final String? emergencyType;
  final String? message;
  final String? source;
  final String? status;
  final double? latitude;
  final double? longitude;
  final String? triggeredAt;
  final String? acknowledgedAt;
  final String? resolvedAt;
  final String? createdAt;
  final String? updatedAt;

  CleaningSosAlertModel({
    this.id,
    this.bookingId,
    this.emergencyType,
    this.message,
    this.source,
    this.status,
    this.latitude,
    this.longitude,
    this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory CleaningSosAlertModel.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data') ? _toMap(json['data']) : json;
    return CleaningSosAlertModel(
      id: _toInt(_pick(data, const <String>['id'])),
      bookingId: _toInt(
        _pick(data, const <String>['bookingId', 'booking_id', 'order_id']),
      ),
      emergencyType: _toStringValue(
        _pick(data, const <String>['emergencyType', 'emergency_type']),
      ),
      message: _toStringValue(_pick(data, const <String>['message'])),
      source: _toStringValue(_pick(data, const <String>['source'])),
      status: _toStringValue(_pick(data, const <String>['status'])),
      latitude: _toDouble(_pick(data, const <String>['latitude', 'lat'])),
      longitude: _toDouble(_pick(data, const <String>['longitude', 'lng'])),
      triggeredAt: _toStringValue(
        _pick(data, const <String>['triggeredAt', 'triggered_at']),
      ),
      acknowledgedAt: _toStringValue(
        _pick(data, const <String>['acknowledgedAt', 'acknowledged_at']),
      ),
      resolvedAt: _toStringValue(
        _pick(data, const <String>['resolvedAt', 'resolved_at']),
      ),
      createdAt: _toStringValue(
        _pick(data, const <String>['createdAt', 'created_at']),
      ),
      updatedAt: _toStringValue(
        _pick(data, const <String>['updatedAt', 'updated_at']),
      ),
    );
  }
}

class FetchSosAlertsModel {
  final List<SosAlertModel> data;

  FetchSosAlertsModel({required this.data});

  factory FetchSosAlertsModel.fromJson(Map<String, dynamic> json) {
    return FetchSosAlertsModel(
      data: _toMapList(json['data']).map(SosAlertModel.fromJson).toList(),
    );
  }
}

class SosAlertModel {
  final int? id;
  final String? status;
  final String? reason;
  final DateTime? createdAt;
  final Map<String, dynamic>? booking;

  SosAlertModel({
    this.id,
    this.status,
    this.reason,
    this.createdAt,
    this.booking,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: _toInt(_pick(json, const <String>['id'])),
      status: _toStringValue(_pick(json, const <String>['status'])),
      reason: _toStringValue(_pick(json, const <String>['reason'])),
      createdAt: parseSosAlertTimestamp(
        _pick(json, const <String>['created_at', 'createdAt', 'updated_at']),
      ),
      booking: _pick(json, const <String>['booking']) is Map
          ? _toMap(_pick(json, const <String>['booking']))
          : null,
    );
  }
}

DateTime? parseSosAlertTimestamp(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;

  final iso = DateTime.tryParse(raw);
  if (iso != null) return iso;

  final parts = raw.split(' ');
  if (parts.length >= 2) {
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');
    if (dateParts.length == 3 && timeParts.length >= 2) {
      return DateTime(
        int.tryParse(dateParts[0]) ?? 0,
        int.tryParse(dateParts[1]) ?? 1,
        int.tryParse(dateParts[2]) ?? 1,
        int.tryParse(timeParts[0]) ?? 0,
        int.tryParse(timeParts[1]) ?? 0,
        timeParts.length >= 3 ? int.tryParse(timeParts[2]) ?? 0 : 0,
      );
    }
  }
  return null;
}
