import 'dart:convert';

import 'fetch_worker_profile_usecase_model.dart';

WorkerWorkingHoursModel workerWorkingHoursModelFromJson(dynamic str) =>
    WorkerWorkingHoursModel.fromJson(str);

String workerWorkingHoursModelToJson(WorkerWorkingHoursModel data) =>
    json.encode(data.toJson());

class WorkerWorkingHoursModel {
  final FetchWorkerProfileUsecaseModelDataDefaultWorkingHours defaultWorkingHours;

  const WorkerWorkingHoursModel({required this.defaultWorkingHours});

  factory WorkerWorkingHoursModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawHours = data is Map
        ? (data['defaultWorkingHours'] ?? data['default_working_hours'])
        : json['defaultWorkingHours'] ?? json['default_working_hours'];

    return WorkerWorkingHoursModel(
      defaultWorkingHours: rawHours is Map
          ? FetchWorkerProfileUsecaseModelDataDefaultWorkingHours.fromJson(
              Map<String, dynamic>.from(rawHours),
            )
          : FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'defaultWorkingHours': defaultWorkingHours.toJson(),
        },
      };
}
