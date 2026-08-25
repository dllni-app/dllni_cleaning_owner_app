import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_room_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assignedRoomsForCurrentWorker', () {
    test('resolves backend preview room ids before worker accepts', () {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'status': 'pending',
        'assignmentMode': 'open_count',
        'numberOfWorkers': 2,
        'myAssignment': <String, dynamic>{
          'workerId': 9,
          'roomIds': <int>[2],
          'isPreview': true,
        },
        'roomAssignments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'roomKey': 'bedroom_1',
            'roomType': 'bedroom',
            'roomSize': 'large',
          },
          <String, dynamic>{
            'id': 2,
            'roomKey': 'bathroom_1',
            'roomType': 'bathroom',
            'roomSize': 'small',
          },
        ],
      });

      final rooms = assignedRoomsForCurrentWorker(order);

      expect(rooms.map((room) => room.id).toList(), <int?>[2]);
      expect(assignedRoomLabel(rooms.single, 0), 'حمام 1 - صغيرة');
    });

    test('uses explicit assigned-to-me flag even without myAssignment', () {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'status': 'pending',
        'assignmentMode': 'open_count',
        'numberOfWorkers': 2,
        'roomAssignments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 3,
            'roomKey': 'bedroom_2',
            'roomType': 'bedroom',
            'roomSize': 'medium',
            'isAssignedToMe': true,
          },
          <String, dynamic>{
            'id': 4,
            'roomKey': 'bedroom_3',
            'roomType': 'bedroom',
            'roomSize': 'medium',
            'isAssignedToMe': false,
          },
        ],
      });

      final rooms = assignedRoomsForCurrentWorker(order);

      expect(rooms.map((room) => room.id).toList(), <int?>[3]);
      expect(assignedRoomLabel(rooms.single, 0), 'غرفة نوم 2 - متوسطة');
    });
  });
}
