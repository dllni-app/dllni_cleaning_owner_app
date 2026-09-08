import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_details_to_list_item_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'retains operational booking details when the detail refresh omits them',
    () {
      final fallback = fetchOrdersUsecaseModelFromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 42,
            'materials': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'name': 'منظف الزجاج',
                'quantity': 2,
                'unitLabel': 'عبوة',
              },
            ],
            'specialServices': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 2,
                'name': 'تنظيف الأريكة',
                'quantity': 1,
                'equipment': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 3, 'name': 'آلة البخار'},
                ],
              },
            ],
            'openTime': <String, dynamic>{
              'isOpenTime': true,
              'requestedWorkerCount': 2,
            },
          },
        ],
      }).data!.single;
      final details = fetchOrderDetailsUsecaseModelFromJson(<String, dynamic>{
        'data': <String, dynamic>{'id': 42, 'status': 'in_progress'},
      }).data!;

      final mapped = OrderDetailsToListItemMapper.fromDetails(
        details,
        fallback: fallback,
      );

      expect(mapped.materials?.single.name, 'منظف الزجاج');
      expect(
        mapped.specialServices?.single.equipment.single.name,
        'آلة البخار',
      );
      expect(mapped.openTime?.isOpenTime, isTrue);
    },
  );

  test(
    'completion refresh keeps materials and special services while replacing open-time final state',
    () {
      final fallback = fetchOrdersUsecaseModelFromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 88,
            'status': 'in_progress',
            'materials': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 10,
                'name': 'منظف الأرضيات',
                'quantity': 1.5,
                'unitLabel': 'لتر',
              },
            ],
            'specialServices': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 11,
                'name': 'تنظيف السجاد',
                'quantity': 2,
                'dirtinessLabel': 'شديد',
              },
            ],
            'openTime': <String, dynamic>{
              'isOpenTime': true,
              'requestedWorkerCount': 2,
              'workStartedAt': '2026-09-07T08:00:00Z',
              'isFinalized': false,
            },
          },
        ],
      }).data!.single;

      final details = fetchOrderDetailsUsecaseModelFromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 88,
          'status': 'awaiting_customer_completion',
          'openTime': <String, dynamic>{
            'isOpenTime': true,
            'requestedWorkerCount': 2,
            'workStartedAt': '2026-09-07T08:00:00Z',
            'workFinishedAt': '2026-09-07T09:15:00Z',
            'actualDurationMinutes': 75,
            'billableDurationMinutes': 90,
            'finalAmount': 300,
            'isFinalized': true,
          },
        },
      }).data!;

      final mapped = OrderDetailsToListItemMapper.fromDetails(
        details,
        fallback: fallback,
      );

      expect(mapped.materials?.single.name, 'منظف الأرضيات');
      expect(mapped.specialServices?.single.name, 'تنظيف السجاد');
      expect(mapped.openTime?.isFinalized, isTrue);
      expect(mapped.openTime?.actualDurationMinutes, 75);
      expect(mapped.openTime?.billableDurationMinutes, 90);
      expect(mapped.openTime?.finalAmount, 300);
    },
  );
}
