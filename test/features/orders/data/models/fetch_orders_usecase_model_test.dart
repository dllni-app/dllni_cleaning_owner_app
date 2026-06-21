import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/property_attribute_labels_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchOrdersUsecaseModel', () {
    test('parses order 73 with breakdown, services, and dispatch eligibility', () {
      final model = fetchOrdersUsecaseModelFromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 73,
            'customerId': 55,
            'preferredWorkerId': 1,
            'assignmentMode': 'preferred_worker',
            'bookingNumber': 'CLN-USER-XU6X1QD3',
            'status': 'pending',
            'statusLabel': 'قيد الانتظار',
            'propertyType': 'office',
            'propertyTypeLabel': 'مكتب',
            'propertyDetails': <String, dynamic>{
              'rooms': 3,
              'bedrooms': 19,
              'kitchens': 3,
              'balconies': 3,
              'bathrooms': 7,
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
            },
            'cleaning_services': <String>[
              'تنظيف عميق',
              'تنظيف المكاتب',
            ],
            'services': <Map<String, dynamic>>[],
            'address': <String, dynamic>{
              'fullAddress': 'حلب - Bustan al-Pasha district',
              'locationName': 'المنزل',
              'latitude': 36.219866,
              'longitude': 37.168432,
            },
            'numberOfRooms': 19,
            'numberOfKitchens': 3,
            'numberOfBalconies': 3,
            'travelFee': 702.5,
            'deliveryFee': 702.5,
            'totalPrice': 5915.25,
            'currency': 'SYP',
            'roomAssignments': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 183,
                'roomKey': 'bedroom.large.1',
                'roomType': 'bedroom',
              },
              <String, dynamic>{
                'id': 182,
                'roomKey': 'bedroom.medium.1',
                'roomType': 'bedroom',
              },
              <String, dynamic>{
                'id': 181,
                'roomKey': 'bedroom.small.1',
                'roomType': 'bedroom',
              },
            ],
          },
        ],
        'dispatchEligibility': <String, dynamic>{
          'canReceiveNewRequests': true,
          'canAcceptNewBookings': true,
          'reasonCode': 'eligible',
          'message': 'Your account can receive and accept new requests.',
        },
      });

      expect(model.data, hasLength(1));
      expect(model.dispatchEligibility?.canReceiveNewRequests, isTrue);

      final order = model.data!.single;
      expect(order.id, 73);
      expect(order.statusLabel, 'قيد الانتظار');
      expect(order.propertyTypeLabel, 'مكتب');
      expect(order.numberOfBalconies, 3);
      expect(order.currency, 'SYP');
      expect(order.travelFee, 702.5);
      expect(order.addressLatitude, 36.219866);
      expect(order.addressLongitude, 37.168432);
      expect(order.propertyDetails?.address, 'حلب - Bustan al-Pasha district');
      expect(order.propertyDetails?.locationName, 'المنزل');
      expect(order.services, hasLength(2));
      expect(order.services!.first.name, 'تنظيف عميق');

      expect(
        PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          order,
          roomType: 'bedroom',
        ),
        3,
      );
      expect(
        PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          order,
          roomType: 'bathroom',
        ),
        7,
      );
      expect(
        PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          order,
          roomType: 'living_room',
        ),
        3,
      );
    });

    test('does not use bedrooms aggregate for bedroom count', () {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'propertyDetails': <String, dynamic>{
          'bedrooms': 19,
          'room_size_breakdown': <String, dynamic>{
            'bedroom': <String, dynamic>{
              'large': 1,
              'small': 1,
              'medium': 1,
            },
          },
        },
        'numberOfRooms': 19,
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
