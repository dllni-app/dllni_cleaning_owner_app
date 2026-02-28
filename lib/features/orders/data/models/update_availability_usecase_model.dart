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

UpdateAvailabilityUsecaseModel updateAvailabilityUsecaseModelFromJson(str) => UpdateAvailabilityUsecaseModel.fromJson(str);

String updateAvailabilityUsecaseModelToJson(UpdateAvailabilityUsecaseModel data) => json.encode(data.toJson());


UpdateAvailabilityUsecaseModelData updateAvailabilityUsecaseModelDataFromJson(str) => UpdateAvailabilityUsecaseModelData.fromJson(str);

String updateAvailabilityUsecaseModelDataToJson(UpdateAvailabilityUsecaseModelData data) => json.encode(data.toJson());


class UpdateAvailabilityUsecaseModel {
  UpdateAvailabilityUsecaseModelData? data;

  UpdateAvailabilityUsecaseModel({
    this.data,
  });

  factory UpdateAvailabilityUsecaseModel.fromJson(Map<String, dynamic> json) {
    return UpdateAvailabilityUsecaseModel(
      data: json['data'] is Map ? UpdateAvailabilityUsecaseModelData.fromJson(Map<String, dynamic>.from(json['data'] as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
    };
  }
}

class UpdateAvailabilityUsecaseModelData {
  int? id;
  bool? isAvailable;
  String? availableFrom;
  String? availableTo;

  UpdateAvailabilityUsecaseModelData({
    this.id,
    this.isAvailable,
    this.availableFrom,
    this.availableTo,
  });

  factory UpdateAvailabilityUsecaseModelData.fromJson(Map<String, dynamic> json) {
    return UpdateAvailabilityUsecaseModelData(
      id: _asInt(json['id']),
      isAvailable: _asBool(json['isAvailable']),
      availableFrom: _asString(json['availableFrom']),
      availableTo: _asString(json['availableTo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isAvailable': isAvailable,
      'availableFrom': availableFrom,
      'availableTo': availableTo,
    };
  }
}