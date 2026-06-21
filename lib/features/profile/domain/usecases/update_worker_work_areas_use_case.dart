import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/profile_repo.dart';
import '../../data/models/worker_work_areas_model.dart';

@lazySingleton
class UpdateWorkerWorkAreasUseCase implements UseCase<WorkerWorkAreasModel, UpdateWorkerWorkAreasParams> {
  final ProfileRepo profile;

  UpdateWorkerWorkAreasUseCase({required this.profile});

  @override
  DataResponse<WorkerWorkAreasModel> call(UpdateWorkerWorkAreasParams params) {
    return profile.updateWorkerWorkAreas(params);
  }
}

class UpdateWorkerWorkAreasParams with Params {
  final List<WorkAreaZoneUpdateItem> zones;

  UpdateWorkerWorkAreasParams({required this.zones});

  @override
  BodyMap getBody() => {
        'zones': zones.map((e) => e.toJson()).toList(),
      };
}

class WorkAreaZoneUpdateItem {
  final int neighborhoodId;
  final String name;
  final bool isActive;

  const WorkAreaZoneUpdateItem({
    required this.neighborhoodId,
    required this.name,
    required this.isActive,
  });

  factory WorkAreaZoneUpdateItem.fromZone(WorkerWorkAreaZone zone) {
    return WorkAreaZoneUpdateItem(
      neighborhoodId: zone.neighborhoodId ?? 0,
      name: zone.name ?? '',
      isActive: zone.isActive ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'neighborhoodId': neighborhoodId,
        'name': name,
        'isActive': isActive,
      };
}

