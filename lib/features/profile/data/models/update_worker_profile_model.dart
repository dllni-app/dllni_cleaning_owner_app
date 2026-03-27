import 'dart:convert';
import 'fetch_worker_profile_usecase_model.dart';

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

UpdateWorkerProfileModel updateWorkerProfileModelFromJson(str) => UpdateWorkerProfileModel.fromJson(str);

String updateWorkerProfileModelToJson(UpdateWorkerProfileModel data) => json.encode(data.toJson());

class UpdateWorkerProfileModel {
  FetchWorkerProfileUsecaseModelData? data;

  UpdateWorkerProfileModel({this.data});

  factory UpdateWorkerProfileModel.fromJson(Map<String, dynamic> json) {
    return UpdateWorkerProfileModel(
      data: json['data'] is Map ? FetchWorkerProfileUsecaseModelData.fromJson(Map<String, dynamic>.from(json['data'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {'data': data?.toJson()};
}
