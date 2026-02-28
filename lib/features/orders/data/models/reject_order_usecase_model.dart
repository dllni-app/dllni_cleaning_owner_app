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

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

List<dynamic>? _asDynamicList(dynamic value) {
  if (value is! List) return null;
  return value.map(_asDynamic).toList();
}

dynamic _asDynamic(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map(_asDynamic).toList();
  }
  if (value is Map) {
    final map = <String, dynamic>{};
    value.forEach((key, nestedValue) {
      map['$key'] = _asDynamic(nestedValue);
    });
    return map;
  }
  if (value is String || value is num || value is bool) {
    return value;
  }
  return value.toString();
}

RejectOrderUsecaseModel rejectOrderUsecaseModelFromJson(str) => RejectOrderUsecaseModel.fromJson(str);

String rejectOrderUsecaseModelToJson(RejectOrderUsecaseModel data) => json.encode(data.toJson());


RejectOrderUsecaseModelData rejectOrderUsecaseModelDataFromJson(str) => RejectOrderUsecaseModelData.fromJson(str);

String rejectOrderUsecaseModelDataToJson(RejectOrderUsecaseModelData data) => json.encode(data.toJson());


class RejectOrderUsecaseModel {
  RejectOrderUsecaseModelData? data;

  RejectOrderUsecaseModel({
    this.data,
  });

  factory RejectOrderUsecaseModel.fromJson(Map<String, dynamic> json) {
    return RejectOrderUsecaseModel(
      data: json['data'] is Map ? RejectOrderUsecaseModelData.fromJson(Map<String, dynamic>.from(json['data'] as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
    };
  }
}

class RejectOrderUsecaseModelData {
  int? id;
  String? status;
  String? cancellationReason;

  RejectOrderUsecaseModelData({
    this.id,
    this.status,
    this.cancellationReason,
  });

  factory RejectOrderUsecaseModelData.fromJson(Map<String, dynamic> json) {
    return RejectOrderUsecaseModelData(
      id: _asInt(json['id']),
      status: _asString(json['status']),
      cancellationReason: _asString(json['cancellationReason']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'cancellationReason': cancellationReason,
    };
  }
}