import 'dart:convert';

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

WorkerWorkAreasModel workerWorkAreasModelFromJson(str) => WorkerWorkAreasModel.fromJson(str);

String workerWorkAreasModelToJson(WorkerWorkAreasModel data) => json.encode(data.toJson());

class WorkerWorkAreasModel {
  final List<WorkerWorkAreaZone> zones;

  const WorkerWorkAreasModel({this.zones = const []});

  factory WorkerWorkAreasModel.fromJson(Map<String, dynamic> json) {
    final rawZones = json['zones'];
    final zones = rawZones is List
        ? rawZones
            .whereType<Map>()
            .map((e) => WorkerWorkAreaZone.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <WorkerWorkAreaZone>[];

    return WorkerWorkAreasModel(zones: zones);
  }

  Map<String, dynamic> toJson() => {
        'zones': zones.map((e) => e.toJson()).toList(),
      };
}

class WorkerWorkAreaZone {
  final int? id;
  final String? name;
  final bool? isActive;

  const WorkerWorkAreaZone({this.id, this.name, this.isActive});

  factory WorkerWorkAreaZone.fromJson(Map<String, dynamic> json) => WorkerWorkAreaZone(
        id: _asInt(json['id']),
        name: _asString(json['name']),
        isActive: _asBool(json['isActive']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isActive': isActive,
      };
}

