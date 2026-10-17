/// Backend-authoritative assignment inventory. A supervised team worker sees
/// only their own checked-out equipment; the supervisor holds the shared kit.
class WorkerBookingInventory {
  const WorkerBookingInventory({
    required this.materials,
    required this.equipment,
  });

  final List<WorkerInventoryLine> materials;
  final List<WorkerInventoryLine> equipment;

  static WorkerBookingInventory fromJson(dynamic response) {
    dynamic data = response;
    if (data is Map) {
      data = data['data'] ?? data;
    }
    if (data is! Map) {
      return const WorkerBookingInventory(materials: [], equipment: []);
    }

    List<WorkerInventoryLine> lines(String key) {
      final raw = data[key];
      if (raw is! List) {
        return [];
      }
      return [
        for (final value in raw)
          if (value is Map)
            WorkerInventoryLine.fromJson(Map<String, dynamic>.from(value)),
      ];
    }

    return WorkerBookingInventory(
      materials: lines('materials'),
      equipment: lines('equipment'),
    );
  }
}

class WorkerInventoryLine {
  const WorkerInventoryLine({
    required this.name,
    required this.status,
    this.quantity,
    this.unit,
    this.assetCode,
  });

  final String name;
  final String status;
  final double? quantity;
  final String? unit;
  final String? assetCode;

  String get statusAr => switch (status) {
    'reserved' => 'محجوز',
    'ready' => 'جاهز للتسليم',
    'issued' || 'handed_over' => 'تم التسليم',
    'acknowledged' || 'received' => 'تم الاستلام',
    'return_pending_confirmation' => 'بانتظار تأكيد الإرجاع',
    'returned' || 'returned_confirmed' => 'تم الإرجاع',
    'failure_pending_confirmation' => 'بلاغ مشكلة قيد المراجعة',
    'damaged' || 'broken' => 'تالف',
    'lost' => 'مفقود',
    'consumed' => 'مستهلك',
    _ => status.isEmpty ? 'غير محدد' : 'قيد المتابعة',
  };

  factory WorkerInventoryLine.fromJson(Map<String, dynamic> data) {
    final quantity = data['issuedQuantity'];
    return WorkerInventoryLine(
      name: (data['name'] ?? 'مادة تنظيف').toString(),
      status: (data['status'] ?? '').toString(),
      quantity: quantity is num ? quantity.toDouble() : null,
      unit: data['unit']?.toString(),
      assetCode: data['assetCode']?.toString(),
    );
  }
}
