Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.map(_map).toList(growable: false);
}

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) continue;
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ??
      double.tryParse(value?.toString() ?? '')?.toInt();
}

double? _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _bool(dynamic value) {
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

String? _string(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

/// Server-calculated material requirement for a booking.
///
/// This is deliberately operational-only: the worker can read the quantity and
/// unit but cannot price or mutate a material line.
class CleaningBookingMaterialLine {
  const CleaningBookingMaterialLine({
    this.id,
    this.name,
    this.quantity,
    this.unit,
    this.unitLabel,
  });

  final int? id;
  final String? name;
  final double? quantity;
  final String? unit;
  final String? unitLabel;

  factory CleaningBookingMaterialLine.fromJson(Map<String, dynamic> json) {
    return CleaningBookingMaterialLine(
      id: _int(_pick(json, const <String>['id', 'materialId', 'material_id'])),
      name: _string(
        _pick(json, const <String>['name', 'materialName', 'material_name']),
      ),
      quantity: _double(_pick(json, const <String>['quantity'])),
      unit: _string(_pick(json, const <String>['unit'])),
      unitLabel: _string(
        _pick(json, const <String>['unitLabel', 'unit_label']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unitLabel': unitLabel,
    };
  }
}

class CleaningMaterialKitDetails {
  const CleaningMaterialKitDetails({
    this.status,
    this.preparedAt,
    this.receivedAt,
    this.receivedByWorkerId,
  });

  final String? status;
  final String? preparedAt;
  final String? receivedAt;
  final int? receivedByWorkerId;

  factory CleaningMaterialKitDetails.fromJson(Map<String, dynamic> json) {
    return CleaningMaterialKitDetails(
      status: _string(json['status']),
      preparedAt: _string(json['preparedAt'] ?? json['prepared_at']),
      receivedAt: _string(json['receivedAt'] ?? json['received_at']),
      receivedByWorkerId: _int(
        json['receivedByWorkerId'] ?? json['received_by_worker_id'],
      ),
    );
  }
}

class CleaningSpecialServiceEquipment {
  const CleaningSpecialServiceEquipment({this.id, this.name});

  final int? id;
  final String? name;

  factory CleaningSpecialServiceEquipment.fromJson(Map<String, dynamic> json) {
    return CleaningSpecialServiceEquipment(
      id: _int(
        _pick(json, const <String>['id', 'equipmentId', 'equipment_id']),
      ),
      name: _string(
        _pick(json, const <String>['name', 'equipmentName', 'equipment_name']),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name};
}

/// Operational details for a server-configured special service.
class CleaningSpecialServiceLine {
  const CleaningSpecialServiceLine({
    this.id,
    this.name,
    this.quantity,
    this.pricingUnit,
    this.pricingUnitLabel,
    this.dirtinessLevel,
    this.dirtinessLabel,
    this.equipment = const <CleaningSpecialServiceEquipment>[],
    this.notes,
    this.executionStatus,
    this.unableReason,
    this.assignedWorkerId,
    this.sessionIds = const <int>[],
    this.items = const <CleaningSpecialServiceItemDetails>[],
    this.equipmentReservations = const <CleaningEquipmentReservationDetails>[],
  });

  final int? id;
  final String? name;
  final double? quantity;
  final String? pricingUnit;
  final String? pricingUnitLabel;
  final String? dirtinessLevel;
  final String? dirtinessLabel;
  final List<CleaningSpecialServiceEquipment> equipment;
  final String? notes;
  final String? executionStatus;
  final String? unableReason;
  final int? assignedWorkerId;
  final List<int> sessionIds;
  final List<CleaningSpecialServiceItemDetails> items;
  final List<CleaningEquipmentReservationDetails> equipmentReservations;

  factory CleaningSpecialServiceLine.fromJson(Map<String, dynamic> json) {
    return CleaningSpecialServiceLine(
      id: _int(_pick(json, const <String>['id', 'serviceId', 'service_id'])),
      name: _string(
        _pick(json, const <String>['name', 'serviceName', 'service_name']),
      ),
      quantity: _double(_pick(json, const <String>['quantity'])),
      pricingUnit: _string(
        _pick(json, const <String>['pricingUnit', 'pricing_unit']),
      ),
      pricingUnitLabel: _string(
        _pick(json, const <String>['pricingUnitLabel', 'pricing_unit_label']),
      ),
      dirtinessLevel: _string(
        _pick(json, const <String>['dirtinessLevel', 'dirtiness_level']),
      ),
      dirtinessLabel: _string(
        _pick(json, const <String>['dirtinessLabel', 'dirtiness_label']),
      ),
      equipment: _mapList(
        json['equipment'],
      ).map(CleaningSpecialServiceEquipment.fromJson).toList(growable: false),
      notes: _string(_pick(json, const <String>['notes', 'note'])),
      executionStatus: _string(
        _pick(json, const <String>['executionStatus', 'execution_status']),
      ),
      unableReason: _string(
        _pick(json, const <String>['unableReason', 'unable_reason']),
      ),
      assignedWorkerId: _int(
        _pick(json, const <String>['assignedWorkerId', 'assigned_worker_id']),
      ),
      sessionIds: (json['sessionIds'] ?? json['session_ids']) is List
          ? (json['sessionIds'] ?? json['session_ids'] as List)
                .map(_int)
                .whereType<int>()
                .toList(growable: false)
          : const <int>[],
      items: _mapList(
        json['items'],
      ).map(CleaningSpecialServiceItemDetails.fromJson).toList(growable: false),
      equipmentReservations:
          _mapList(
                json['equipmentReservations'] ?? json['equipment_reservations'],
              )
              .map(CleaningEquipmentReservationDetails.fromJson)
              .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'quantity': quantity,
      'pricingUnit': pricingUnit,
      'pricingUnitLabel': pricingUnitLabel,
      'dirtinessLevel': dirtinessLevel,
      'dirtinessLabel': dirtinessLabel,
      'equipment': equipment
          .map((item) => item.toJson())
          .toList(growable: false),
      'notes': notes,
      'executionStatus': executionStatus,
      'unableReason': unableReason,
      'assignedWorkerId': assignedWorkerId,
      'sessionIds': sessionIds,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'equipmentReservations': equipmentReservations
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class CleaningSpecialServiceItemDetails {
  const CleaningSpecialServiceItemDetails({
    this.id,
    this.quantity,
    this.dirtinessLevel,
    this.notes,
    this.beforeImages = const <String>[],
    this.afterImages = const <String>[],
  });

  final int? id;
  final double? quantity;
  final String? dirtinessLevel;
  final String? notes;
  final List<String> beforeImages;
  final List<String> afterImages;

  factory CleaningSpecialServiceItemDetails.fromJson(
    Map<String, dynamic> json,
  ) {
    List<String> images(dynamic value) => value is List
        ? value.map(_string).whereType<String>().toList(growable: false)
        : const <String>[];

    return CleaningSpecialServiceItemDetails(
      id: _int(json['id']),
      quantity: _double(json['quantity']),
      dirtinessLevel: _string(
        json['dirtinessLevel'] ?? json['dirtiness_level'],
      ),
      notes: _string(json['notes']),
      beforeImages: images(json['beforeImages'] ?? json['before_images']),
      afterImages: images(json['afterImages'] ?? json['after_images']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'quantity': quantity,
    'dirtinessLevel': dirtinessLevel,
    'notes': notes,
    'beforeImages': beforeImages,
    'afterImages': afterImages,
  };
}

class CleaningEquipmentReservationDetails {
  const CleaningEquipmentReservationDetails({
    this.id,
    this.equipmentId,
    this.name,
    this.assetCode,
    this.status,
    this.reservedFrom,
    this.reservedUntil,
    this.failureReason,
  });

  final int? id;
  final int? equipmentId;
  final String? name;
  final String? assetCode;
  final String? status;
  final String? reservedFrom;
  final String? reservedUntil;
  final String? failureReason;

  factory CleaningEquipmentReservationDetails.fromJson(
    Map<String, dynamic> json,
  ) {
    return CleaningEquipmentReservationDetails(
      id: _int(json['id']),
      equipmentId: _int(json['equipmentId'] ?? json['equipment_id']),
      name: _string(json['name']),
      assetCode: _string(json['assetCode'] ?? json['asset_code']),
      status: _string(json['status']),
      reservedFrom: _string(json['reservedFrom'] ?? json['reserved_from']),
      reservedUntil: _string(json['reservedUntil'] ?? json['reserved_until']),
      failureReason: _string(json['failureReason'] ?? json['failure_reason']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'equipmentId': equipmentId,
    'name': name,
    'assetCode': assetCode,
    'status': status,
    'reservedFrom': reservedFrom,
    'reservedUntil': reservedUntil,
    'failureReason': failureReason,
  };
}

/// Server-authoritative Open-Time metadata. The client uses it only for
/// presentation and never derives a bill, a payout, or a final price.
class CleaningOpenTimeDetails {
  const CleaningOpenTimeDetails({
    this.isOpenTime,
    this.hourlyRate,
    this.requestedWorkerCount,
    this.workStartedAt,
    this.workFinishedAt,
    this.actualDurationMinutes,
    this.billableDurationMinutes,
    this.finalAmount,
    this.isFinalized,
    this.serverNow,
    this.ceilingEndsAt,
    this.expectedMaxMinutes,
    this.hardMaxMinutes,
    this.warningMinutes,
    this.extensionOptions = const <int>[],
    this.remainingMinutes,
    this.liveAmount,
    this.liveBillableMinutes,
    this.endStatus,
    this.pendingExtension,
  });

  final bool? isOpenTime;
  final double? hourlyRate;
  final int? requestedWorkerCount;
  final String? workStartedAt;
  final String? workFinishedAt;
  final int? actualDurationMinutes;
  final int? billableDurationMinutes;
  final double? finalAmount;
  final bool? isFinalized;
  final String? serverNow;
  final String? ceilingEndsAt;
  final int? expectedMaxMinutes;
  final int? hardMaxMinutes;
  final int? warningMinutes;
  final List<int> extensionOptions;
  final int? remainingMinutes;
  final double? liveAmount;
  final int? liveBillableMinutes;
  final String? endStatus;
  final CleaningOpenTimeExtensionDetails? pendingExtension;

  factory CleaningOpenTimeDetails.fromJson(Map<String, dynamic> json) {
    return CleaningOpenTimeDetails(
      isOpenTime: _bool(
        _pick(json, const <String>['isOpenTime', 'is_open_time']),
      ),
      hourlyRate: _double(
        _pick(json, const <String>['hourlyRate', 'hourly_rate']),
      ),
      requestedWorkerCount: _int(
        _pick(json, const <String>[
          'requestedWorkerCount',
          'requested_worker_count',
        ]),
      ),
      workStartedAt: _string(
        _pick(json, const <String>['workStartedAt', 'work_started_at']),
      ),
      workFinishedAt: _string(
        _pick(json, const <String>['workFinishedAt', 'work_finished_at']),
      ),
      actualDurationMinutes: _int(
        _pick(json, const <String>[
          'actualDurationMinutes',
          'actual_duration_minutes',
        ]),
      ),
      billableDurationMinutes: _int(
        _pick(json, const <String>[
          'billableDurationMinutes',
          'billable_duration_minutes',
        ]),
      ),
      finalAmount: _double(
        _pick(json, const <String>['finalAmount', 'final_amount']),
      ),
      isFinalized: _bool(
        _pick(json, const <String>['isFinalized', 'is_finalized']),
      ),
      serverNow: _string(
        _pick(json, const <String>['serverNow', 'server_now']),
      ),
      ceilingEndsAt: _string(
        _pick(json, const <String>['ceilingEndsAt', 'ceiling_ends_at']),
      ),
      expectedMaxMinutes: _int(
        _pick(json, const <String>[
          'expectedMaxMinutes',
          'expected_max_minutes',
        ]),
      ),
      hardMaxMinutes: _int(
        _pick(json, const <String>['hardMaxMinutes', 'hard_max_minutes']),
      ),
      warningMinutes: _int(
        _pick(json, const <String>['warningMinutes', 'warning_minutes']),
      ),
      extensionOptions:
          (json['extensionOptions'] ?? json['extension_options']) is List
          ? (json['extensionOptions'] ?? json['extension_options'] as List)
                .map(_int)
                .whereType<int>()
                .toList(growable: false)
          : const <int>[],
      remainingMinutes: _int(
        _pick(json, const <String>['remainingMinutes', 'remaining_minutes']),
      ),
      liveAmount: _double(
        _pick(json, const <String>['liveAmount', 'live_amount']),
      ),
      liveBillableMinutes: _int(
        _pick(json, const <String>[
          'liveBillableMinutes',
          'live_billable_minutes',
        ]),
      ),
      endStatus: _string(
        _pick(json, const <String>['endStatus', 'end_status']),
      ),
      pendingExtension:
          (json['pendingExtension'] ?? json['pending_extension']) is Map
          ? CleaningOpenTimeExtensionDetails.fromJson(
              _map(json['pendingExtension'] ?? json['pending_extension']),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isOpenTime': isOpenTime,
      'hourlyRate': hourlyRate,
      'requestedWorkerCount': requestedWorkerCount,
      'workStartedAt': workStartedAt,
      'workFinishedAt': workFinishedAt,
      'actualDurationMinutes': actualDurationMinutes,
      'billableDurationMinutes': billableDurationMinutes,
      'finalAmount': finalAmount,
      'isFinalized': isFinalized,
      'serverNow': serverNow,
      'ceilingEndsAt': ceilingEndsAt,
      'expectedMaxMinutes': expectedMaxMinutes,
      'hardMaxMinutes': hardMaxMinutes,
      'warningMinutes': warningMinutes,
      'extensionOptions': extensionOptions,
      'remainingMinutes': remainingMinutes,
      'liveAmount': liveAmount,
      'liveBillableMinutes': liveBillableMinutes,
      'endStatus': endStatus,
      'pendingExtension': pendingExtension?.toJson(),
    };
  }
}

class CleaningOpenTimeExtensionDetails {
  const CleaningOpenTimeExtensionDetails({
    this.id,
    this.requestedMinutes,
    this.status,
    this.decisionReason,
  });

  final int? id;
  final int? requestedMinutes;
  final String? status;
  final String? decisionReason;

  factory CleaningOpenTimeExtensionDetails.fromJson(Map<String, dynamic> json) {
    return CleaningOpenTimeExtensionDetails(
      id: _int(json['id']),
      requestedMinutes: _int(
        json['requestedMinutes'] ?? json['requested_minutes'],
      ),
      status: _string(json['status']),
      decisionReason: _string(
        json['decisionReason'] ?? json['decision_reason'],
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'requestedMinutes': requestedMinutes,
    'status': status,
    'decisionReason': decisionReason,
  };
}

CleaningOpenTimeDetails cleaningOpenTimeEnvelopeFromJson(dynamic value) {
  final root = _map(value);
  final data = _map(root['data'] ?? root);
  return CleaningOpenTimeDetails.fromJson(
    _map(data['openTime'] ?? data['open_time'] ?? data),
  );
}

class CleaningOperationalActionResult {
  const CleaningOperationalActionResult({
    this.specialService,
    this.reservation,
    this.materialKit,
  });

  final CleaningSpecialServiceLine? specialService;
  final CleaningEquipmentReservationDetails? reservation;
  final CleaningMaterialKitDetails? materialKit;

  factory CleaningOperationalActionResult.fromJson(dynamic value) {
    final root = _map(value);
    final data = _map(root['data'] ?? root);
    return CleaningOperationalActionResult(
      specialService: data['specialService'] is Map
          ? CleaningSpecialServiceLine.fromJson(_map(data['specialService']))
          : null,
      reservation: data['reservation'] is Map
          ? CleaningEquipmentReservationDetails.fromJson(
              _map(data['reservation']),
            )
          : null,
      materialKit: data['materialKit'] is Map
          ? CleaningMaterialKitDetails.fromJson(_map(data['materialKit']))
          : null,
    );
  }
}

CleaningOperationalActionResult cleaningOperationalActionResultFromJson(
  dynamic value,
) => CleaningOperationalActionResult.fromJson(value);
