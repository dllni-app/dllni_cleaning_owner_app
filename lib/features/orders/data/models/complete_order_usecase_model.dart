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

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

CompleteOrderUsecaseModel completeOrderUsecaseModelFromJson(str) =>
    CompleteOrderUsecaseModel.fromJson(str);

String completeOrderUsecaseModelToJson(CompleteOrderUsecaseModel data) =>
    json.encode(data.toJson());

CompleteOrderUsecaseModelData completeOrderUsecaseModelDataFromJson(str) =>
    CompleteOrderUsecaseModelData.fromJson(str);

String completeOrderUsecaseModelDataToJson(CompleteOrderUsecaseModelData data) =>
    json.encode(data.toJson());

class CompleteOrderUsecaseModel {
  CompleteOrderUsecaseModelData? data;

  CompleteOrderUsecaseModel({this.data});

  factory CompleteOrderUsecaseModel.fromJson(Map<String, dynamic> json) {
    return CompleteOrderUsecaseModel(
      data: json['data'] is Map
          ? CompleteOrderUsecaseModelData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data?.toJson()};
  }
}

class CompleteOrderUsecaseModelData {
  int? id;
  String? status;
  String? workFinishedAt;
  String? note;

  CompleteOrderUsecaseModelData({
    this.id,
    this.status,
    this.workFinishedAt,
    this.note,
  });

  factory CompleteOrderUsecaseModelData.fromJson(Map<String, dynamic> json) {
    return CompleteOrderUsecaseModelData(
      id: _asInt(json['id']),
      status: _asString(json['status']),
      workFinishedAt: _asString(
        _pick(json, const <String>['workFinishedAt', 'work_finished_at']),
      ),
      note: _asString(
        _pick(json, const <String>[
          'workerCompletionMessage',
          'worker_completion_message',
        ]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'workFinishedAt': workFinishedAt,
      'note': note,
    };
  }
}
