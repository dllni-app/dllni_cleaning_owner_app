import 'dart:convert';

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
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

StartWorkModel startWorkModelFromJson(dynamic str) {
  final map = str is String ? json.decode(str) as Map<String, dynamic> : Map<String, dynamic>.from(str as Map);
  return StartWorkModel.fromJson(map);
}

class StartWorkModel {
  StartWorkModel({this.data});

  StartWorkModelData? data;

  factory StartWorkModel.fromJson(Map<String, dynamic> json) {
    return StartWorkModel(
      data: json['data'] is Map ? StartWorkModelData.fromJson(Map<String, dynamic>.from(json['data'] as Map)) : null,
    );
  }
}

class StartWorkModelData {
  StartWorkModelData({this.id, this.status, this.workStartedAt});

  int? id;
  String? status;
  String? workStartedAt;

  factory StartWorkModelData.fromJson(Map<String, dynamic> json) {
    return StartWorkModelData(
      id: _asInt(json['id']),
      status: _asString(json['status']),
      workStartedAt: _asString(json['workStartedAt']),
    );
  }
}
