import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_inventory.dart';

void main() {
  test('decodes worker-specific consumable and returnable equipment', () {
    final inventory = WorkerBookingInventory.fromJson({
      'data': {
        'bookingId': 12,
        'materials': [
          {
            'name': 'سائل تنظيف',
            'issuedQuantity': 2,
            'unit': 'L',
            'status': 'issued',
          },
        ],
        'equipment': [
          {
            'name': 'مكنسة كهربائية',
            'assetCode': 'VAC-04',
            'status': 'handed_over',
          },
        ],
      },
    });
    expect(inventory.materials.single.quantity, 2);
    expect(inventory.materials.single.unit, 'L');
    expect(inventory.equipment.single.assetCode, 'VAC-04');
    expect(inventory.equipment.single.status, 'handed_over');
  });

  test('does not invent kit lines when group worker has no custody', () {
    final inventory = WorkerBookingInventory.fromJson({
      'data': {'materials': [], 'equipment': []},
    });
    expect(inventory.materials, isEmpty);
    expect(inventory.equipment, isEmpty);
  });
}
