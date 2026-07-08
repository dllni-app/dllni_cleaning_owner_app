import 'package:dllni_cleaninig_owner_app/features/orders/data/models/arrive_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_mission_task_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderMissionTaskMapper.build', () {
    test('builds one task per assigned room with label and size detail', () {
      final order = FetchOrdersUsecaseModelDataItem.fromJson(<String, dynamic>{
        'id': 123,
        'my_assignment': <String, dynamic>{
          'workerId': 9,
          'status': 'accepted',
        },
        'room_assignments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'roomKey': 'bedroom_1',
            'roomType': 'bedroom',
            'roomTypeLabel': 'غرفة نوم',
            'roomSize': 'large',
            'roomSizeLabel': 'كبيرة',
            'assignedWorkerId': 9,
            'isAssignedToMe': true,
          },
          <String, dynamic>{
            'id': 2,
            'roomKey': 'bathroom_1',
            'roomType': 'bathroom',
            'roomTypeLabel': 'حمام',
            'roomSize': 'medium',
            'roomSizeLabel': 'متوسطة',
            'assignedWorkerId': 9,
            'isAssignedToMe': true,
          },
        ],
      });

      final tasks = OrderMissionTaskMapper.build(order: order);

      expect(tasks, hasLength(2));
      expect(tasks[0].label, 'غرفة نوم 1');
      expect(tasks[0].detail, 'كبيرة');
      expect(tasks[1].label, 'حمام 1');
      expect(tasks[1].detail, 'متوسطة');
    });

    test('uses all room assignments when worker has no assigned subset', () {
      final order = FetchOrdersUsecaseModelDataItem.fromJson(<String, dynamic>{
        'id': 73,
        'roomAssignments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 183,
            'roomKey': 'bedroom.large.1',
            'roomType': 'bedroom',
            'roomSize': 'large',
          },
          <String, dynamic>{
            'id': 182,
            'roomKey': 'bedroom.medium.2',
            'roomType': 'bedroom',
            'roomSize': 'medium',
          },
        ],
      });

      final tasks = OrderMissionTaskMapper.build(order: order);

      expect(tasks, hasLength(2));
      expect(tasks[0].label, 'غرفة نوم 1');
      expect(tasks[0].detail, 'كبيرة');
      expect(tasks[1].label, 'غرفة نوم 2');
      expect(tasks[1].detail, 'متوسطة');
    });

    test('does not build room checklist for event assistance orders', () {
      final order = FetchOrdersUsecaseModelDataItem.fromJson(<String, dynamic>{
        'id': 91,
        'propertyType': 'event_assistance',
        'roomAssignments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 183,
            'roomKey': 'bedroom.large.1',
            'roomType': 'bedroom',
            'roomSize': 'large',
          },
        ],
        'propertyDetails': <String, dynamic>{
          'room_size_breakdown': <String, dynamic>{
            'bedroom': <String, dynamic>{
              'large': 1,
            },
          },
        },
      });

      final tasks = OrderMissionTaskMapper.build(order: order);

      expect(tasks, isEmpty);
    });

    test('expands room size breakdown into individual room tasks', () {
      final order = FetchOrdersUsecaseModelDataItem.fromJson(<String, dynamic>{
        'id': 10,
        'propertyDetails': <String, dynamic>{
          'room_size_breakdown': <String, dynamic>{
            'bedroom': <String, dynamic>{
              'large': 1,
              'small': 2,
            },
          },
        },
      });

      final tasks = OrderMissionTaskMapper.build(order: order);

      expect(tasks, hasLength(3));
      expect(tasks[0].label, 'غرفة نوم 1');
      expect(tasks[0].detail, 'كبيرة');
      expect(tasks[1].label, 'غرفة نوم 2');
      expect(tasks[1].detail, 'صغيرة');
      expect(tasks[2].label, 'غرفة نوم 3');
      expect(tasks[2].detail, 'صغيرة');
    });

    test('returns empty checklist when no room data exists', () {
      final order = FetchOrdersUsecaseModelDataItem(id: 1);

      final tasks = OrderMissionTaskMapper.build(order: order);

      expect(tasks, isEmpty);
    });
  });

  group('OrderMissionTaskMapper.buildServicesInfo', () {
    test('builds service and addon info rows', () {
      final tasks = OrderMissionTaskMapper.buildServicesInfo(
        services: <Service>[
          Service(name: 'تنظيف عميق', quantity: 1),
          Service(name: 'تنظيف نوافذ', quantity: 2),
        ],
        addons: <Addon>[
          Addon(name: 'مكواة', quantity: 1),
        ],
      );

      expect(tasks, hasLength(3));
      expect(tasks[0].label, 'تنظيف عميق');
      expect(tasks[0].detail, isNull);
      expect(tasks[1].label, 'تنظيف نوافذ');
      expect(tasks[1].detail, 'x2');
      expect(tasks[2].label, 'مكواة');
    });
  });
}
