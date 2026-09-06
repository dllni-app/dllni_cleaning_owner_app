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
    };
  }
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
    };
  }
}
