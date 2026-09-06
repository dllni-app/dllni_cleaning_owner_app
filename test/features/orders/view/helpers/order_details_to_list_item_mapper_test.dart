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
}
