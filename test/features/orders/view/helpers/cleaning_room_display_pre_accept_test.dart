import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_room_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'room labels use requested room metadata, never a worker assignment',
    () {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'numberOfWorkers': 2,
        'roomAssignments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'roomKey': 'bedroom_1',
            'roomType': 'bedroom',
            'roomSize': 'large',
            'assignedWorkerId': 42,
          },
          <String, dynamic>{
            'id': 2,
            'roomKey': 'bathroom_1',
            'roomType': 'bathroom',
            'roomSize': 'small',
          },
        ],
      });
      expect(order.roomAssignments, hasLength(2));
      expect(order.roomAssignments!.first.roomType, 'bedroom');
      expect(bookingRoomLabel(order.roomAssignments![1], 1), 'حمام 1 - صغيرة');
    },
  );
}
