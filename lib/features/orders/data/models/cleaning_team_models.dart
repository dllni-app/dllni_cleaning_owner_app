int? _teamToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _teamToDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _teamToBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

String? _teamToStringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

dynamic _teamPick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

class CleaningWorkerAcceptanceModel {
  final int? required;
  final int? accepted;
  final int? remaining;
  final bool? isFulfilled;

  CleaningWorkerAcceptanceModel({
    this.required,
    this.accepted,
    this.remaining,
    this.isFulfilled,
  });

  factory CleaningWorkerAcceptanceModel.fromJson(Map<String, dynamic> json) {
    return CleaningWorkerAcceptanceModel(
      required: _teamToInt(_teamPick(json, const <String>['required'])),
      accepted: _teamToInt(_teamPick(json, const <String>['accepted'])),
      remaining: _teamToInt(_teamPick(json, const <String>['remaining'])),
      isFulfilled: _teamToBool(
        _teamPick(json, const <String>['isFulfilled', 'is_fulfilled']),
      ),
    );
  }
}

class CleaningMyAssignmentModel {
  final int? id;
  final int? workerId;
  final String? status;
  final String? acceptedAt;
  final String? startedTravelAt;
  final String? arrivedAt;
  final String? startApprovedAt;
  final String? workStartedAt;
  final String? workFinishedAt;
  final int? roomCount;
  final double? roomsWeight;
  final double? serviceShareAmount;
  final double? travelFee;
  final double? adminMarginAmount;
  final double? workerAmount;
  final String? currency;
  final List<int>? roomIds;

  CleaningMyAssignmentModel({
    this.id,
    this.workerId,
    this.status,
    this.acceptedAt,
    this.startedTravelAt,
    this.arrivedAt,
    this.startApprovedAt,
    this.workStartedAt,
    this.workFinishedAt,
    this.roomCount,
    this.roomsWeight,
    this.serviceShareAmount,
    this.travelFee,
    this.adminMarginAmount,
    this.workerAmount,
    this.currency,
    this.roomIds,
  });

  factory CleaningMyAssignmentModel.fromJson(Map<String, dynamic> json) {
    final roomIdsRaw = json['roomIds'] ?? json['room_ids'];
    final roomIds = roomIdsRaw is List
        ? roomIdsRaw.map((item) => _teamToInt(item)).whereType<int>().toList()
        : null;

    return CleaningMyAssignmentModel(
      id: _teamToInt(_teamPick(json, const <String>['id'])),
      workerId: _teamToInt(_teamPick(json, const <String>['workerId', 'worker_id'])),
      status: _teamToStringValue(_teamPick(json, const <String>['status'])),
      acceptedAt: _teamToStringValue(
        _teamPick(json, const <String>['acceptedAt', 'accepted_at']),
      ),
      startedTravelAt: _teamToStringValue(
        _teamPick(json, const <String>['startedTravelAt', 'started_travel_at']),
      ),
      arrivedAt: _teamToStringValue(
        _teamPick(json, const <String>['arrivedAt', 'arrived_at']),
      ),
      startApprovedAt: _teamToStringValue(
        _teamPick(json, const <String>['startApprovedAt', 'start_approved_at']),
      ),
      workStartedAt: _teamToStringValue(
        _teamPick(json, const <String>['workStartedAt', 'work_started_at']),
      ),
      workFinishedAt: _teamToStringValue(
        _teamPick(json, const <String>['workFinishedAt', 'work_finished_at']),
      ),
      roomCount: _teamToInt(_teamPick(json, const <String>['roomCount', 'room_count'])),
      roomsWeight: _teamToDouble(
        _teamPick(json, const <String>['roomsWeight', 'rooms_weight']),
      ),
      serviceShareAmount: _teamToDouble(
        _teamPick(
          json,
          const <String>['serviceShareAmount', 'service_share_amount'],
        ),
      ),
      travelFee: _teamToDouble(
        _teamPick(json, const <String>['travelFee', 'travel_fee']),
      ),
      adminMarginAmount: _teamToDouble(
        _teamPick(json, const <String>['adminMarginAmount', 'admin_margin_amount']),
      ),
      workerAmount: _teamToDouble(
        _teamPick(json, const <String>['workerAmount', 'worker_amount']),
      ),
      currency: _teamToStringValue(_teamPick(json, const <String>['currency'])),
      roomIds: roomIds,
    );
  }
}

class CleaningRoomAssignmentModel {
  final int? id;
  final String? roomKey;
  final String? roomType;
  final String? roomTypeLabel;
  final String? roomSize;
  final String? roomSizeLabel;
  final String? displayLabel;
  final double? weight;
  final int? assignedWorkerId;
  final bool isAssignedToMe;
  final String? assignmentSource;

  CleaningRoomAssignmentModel({
    this.id,
    this.roomKey,
    this.roomType,
    this.roomTypeLabel,
    this.roomSize,
    this.roomSizeLabel,
    this.displayLabel,
    this.weight,
    this.assignedWorkerId,
    this.isAssignedToMe = false,
    this.assignmentSource,
  });

  factory CleaningRoomAssignmentModel.fromJson(Map<String, dynamic> json) {
    return CleaningRoomAssignmentModel(
      id: _teamToInt(_teamPick(json, const <String>['id'])),
      roomKey: _teamToStringValue(
        _teamPick(json, const <String>['roomKey', 'room_key']),
      ),
      roomType: _teamToStringValue(
        _teamPick(json, const <String>['roomType', 'room_type']),
      ),
      roomTypeLabel: _teamToStringValue(
        _teamPick(json, const <String>['roomTypeLabel', 'room_type_label']),
      ),
      roomSize: _teamToStringValue(
        _teamPick(json, const <String>['roomSize', 'room_size']),
      ),
      roomSizeLabel: _teamToStringValue(
        _teamPick(json, const <String>['roomSizeLabel', 'room_size_label']),
      ),
      displayLabel: _teamToStringValue(
        _teamPick(json, const <String>['displayLabel', 'display_label']),
      ),
      weight: _teamToDouble(_teamPick(json, const <String>['weight'])),
      assignedWorkerId: _teamToInt(
        _teamPick(json, const <String>['assignedWorkerId', 'assigned_worker_id']),
      ),
      isAssignedToMe: _teamToBool(
            _teamPick(json, const <String>['isAssignedToMe', 'is_assigned_to_me']),
          ) ??
          false,
      assignmentSource: _teamToStringValue(
        _teamPick(json, const <String>['assignmentSource', 'assignment_source']),
      ),
    );
  }
}

class CleaningWorkerAssignmentModel {
  final int? id;
  final int? workerId;
  final String? status;
  final String? startedTravelAt;
  final String? arrivedAt;
  final String? startApprovedAt;
  final String? workStartedAt;
  final String? workFinishedAt;
  final int? roomCount;
  final double? workerAmount;
  final List<int>? roomIds;

  CleaningWorkerAssignmentModel({
    this.id,
    this.workerId,
    this.status,
    this.startedTravelAt,
    this.arrivedAt,
    this.startApprovedAt,
    this.workStartedAt,
    this.workFinishedAt,
    this.roomCount,
    this.workerAmount,
    this.roomIds,
  });

  factory CleaningWorkerAssignmentModel.fromJson(Map<String, dynamic> json) {
    final roomIdsRaw = json['roomIds'] ?? json['room_ids'];
    final roomIds = roomIdsRaw is List
        ? roomIdsRaw.map((item) => _teamToInt(item)).whereType<int>().toList()
        : null;

    return CleaningWorkerAssignmentModel(
      id: _teamToInt(_teamPick(json, const <String>['id'])),
      workerId: _teamToInt(_teamPick(json, const <String>['workerId', 'worker_id'])),
      status: _teamToStringValue(_teamPick(json, const <String>['status'])),
      startedTravelAt: _teamToStringValue(
        _teamPick(json, const <String>['startedTravelAt', 'started_travel_at']),
      ),
      arrivedAt: _teamToStringValue(
        _teamPick(json, const <String>['arrivedAt', 'arrived_at']),
      ),
      startApprovedAt: _teamToStringValue(
        _teamPick(json, const <String>['startApprovedAt', 'start_approved_at']),
      ),
      workStartedAt: _teamToStringValue(
        _teamPick(json, const <String>['workStartedAt', 'work_started_at']),
      ),
      workFinishedAt: _teamToStringValue(
        _teamPick(json, const <String>['workFinishedAt', 'work_finished_at']),
      ),
      roomCount: _teamToInt(_teamPick(json, const <String>['roomCount', 'room_count'])),
      workerAmount: _teamToDouble(
        _teamPick(json, const <String>['workerAmount', 'worker_amount']),
      ),
      roomIds: roomIds,
    );
  }
}
