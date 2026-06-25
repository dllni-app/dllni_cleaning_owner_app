import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/property_attribute_labels_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PropertyAttributeLabelsHelper', () {
    test('builds chips from room_size_breakdown', () {
      final property = PropertyDetailsData.fromJson(<String, dynamic>{
        'bedrooms': 19,
        'bathrooms': 7,
        'kitchens': 3,
        'balconies': 3,
        'living_room_size': 'large',
        'living_room_size_label': 'كبيرة',
        'room_size_breakdown': <String, dynamic>{
          'balcony': <String, dynamic>{
            'large': 1,
            'small': 1,
            'medium': 1,
          },
          'bedroom': <String, dynamic>{
            'large': 1,
            'small': 1,
            'medium': 1,
          },
          'kitchen': <String, dynamic>{
            'large': 1,
            'small': 1,
            'medium': 1,
          },
          'bathroom': <String, dynamic>{
            'large': 3,
            'small': 1,
            'medium': 3,
          },
          'living_room': <String, dynamic>{
            'large': 1,
            'small': 1,
            'medium': 1,
          },
        },
      });

      expect(
        PropertyAttributeLabelsHelper.build(property),
        <String>[
          '1 غرفة نوم كبيرة',
          '1 غرفة نوم متوسطة',
          '1 غرفة نوم صغيرة',
          '3 حمام كبيرة',
          '3 حمام متوسطة',
          '1 حمام صغيرة',
          '1 مطبخ كبيرة',
          '1 مطبخ متوسطة',
          '1 مطبخ صغيرة',
          '1 غرفة معيشة كبيرة',
          '1 غرفة معيشة متوسطة',
          '1 غرفة معيشة صغيرة',
          '1 شرفة كبيرة',
          '1 شرفة متوسطة',
          '1 شرفة صغيرة',
        ],
      );
    });

    test('roomTypeCount sums all sizes in breakdown', () {
      final property = PropertyDetailsData.fromJson(<String, dynamic>{
        'room_size_breakdown': <String, dynamic>{
          'bathroom': <String, dynamic>{
            'large': 3,
            'small': 1,
            'medium': 3,
          },
          'bedroom': <String, dynamic>{
            'large': 1,
            'small': 1,
            'medium': 1,
          },
        },
      });

      expect(
        PropertyAttributeLabelsHelper.roomTypeCount(
          property,
          roomType: 'bathroom',
        ),
        7,
      );
      expect(
        PropertyAttributeLabelsHelper.roomTypeCount(
          property,
          roomType: 'bedroom',
        ),
        3,
      );
    });

    test('falls back to legacy aggregate fields when breakdown is missing', () {
      final property = PropertyDetailsData.fromJson(<String, dynamic>{
        'bedrooms': 3,
        'bathrooms': 2,
        'kitchens': 1,
        'balconies': 2,
        'living_room_size_label': 'كبيرة',
      });

      expect(
        PropertyAttributeLabelsHelper.build(property),
        <String>[
          '2 حمام',
          '3 غرف نوم',
          '1 مطبخ',
          '2 شرفة',
          'غرفة معيشة كبيرة',
        ],
      );
    });
    test('roomTypeCountForOrder falls back to roomAssignments', () {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'propertyDetails': <String, dynamic>{
          'bedrooms': 19,
        },
        'roomAssignments': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'roomType': 'bedroom'},
          <String, dynamic>{'id': 2, 'roomType': 'bedroom'},
          <String, dynamic>{'id': 3, 'roomType': 'bedroom'},
        ],
      });

      expect(
        PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          order,
          roomType: 'bedroom',
        ),
        3,
      );
    });
  });
}
