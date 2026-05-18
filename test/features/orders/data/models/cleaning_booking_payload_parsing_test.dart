import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cleaning booking payload parsing', () {
    test('parses full details payload with tracking + snake/camel aliases', () {
      final model = fetchOrderDetailsUsecaseModelFromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 700,
          'booking_number': 'CL-700',
          'status': CleaningBookingStatus.workerAssigned,
          'customer_id': 11,
          'workerId': 22,
          'cancellation_fee': '15.75',
          'total_price': 110.25,
          'tracking': <String, dynamic>{
            'started_travel_at': '2026-05-17T09:30:00Z',
            'address_latitude': '33.50',
            'address_longitude': 36.30,
          },
          'customer': <String, dynamic>{
            'id': 11,
            'name': 'Ahmad',
            'phone': '0999999',
            'email': 'ahmad@example.com',
          },
          'worker': <String, dynamic>{
            'id': 22,
            'first_name': 'Sami',
            'phone': '0988888',
          },
          'services': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'name': 'Kitchen', 'quantity': 1},
          ],
          'addons': <Map<String, dynamic>>[
            <String, dynamic>{'id': 2, 'name': 'Windows', 'quantity': 2},
          ],
          'billing_policy': <String, dynamic>{
            'id': 3,
            'billing_mode': 'hourly',
          },
          'time_warnings': <Map<String, dynamic>>[
            <String, dynamic>{'id': 8, 'requested_minutes': 20},
          ],
          'disputes': <Map<String, dynamic>>[
            <String, dynamic>{'id': 9, 'status': 'open'},
          ],
        },
      });

      final data = model.data;
      expect(data, isNotNull);
      expect(data!.bookingNumber, 'CL-700');
      expect(data.customerId, 11);
      expect(data.workerId, 22);
      expect(data.startedTravelAt, '2026-05-17T09:30:00Z');
      expect(data.addressLatitude, 33.50);
      expect(data.addressLongitude, 36.30);
      expect(data.cancellationFee, 15.75);
      expect(data.customer?.name, 'Ahmad');
      expect(data.worker?.name, 'Sami');
      expect(data.services?.first.name, 'Kitchen');
      expect(data.addons?.first.quantity, 2);
      expect(data.billingPolicy?.raw['id'], 3);
      expect((data.timeWarnings ?? <dynamic>[]).isNotEmpty, isTrue);
      expect((data.disputes ?? <dynamic>[]).isNotEmpty, isTrue);
    });

    test('parses list payload with tracking normalization', () {
      final model = fetchOrdersUsecaseModelFromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 42,
            'status': CleaningBookingStatus.workerAssigned,
            'tracking': <String, dynamic>{
              'arrived_at': '2026-05-17T10:00:00Z',
              'work_started_at': '2026-05-17T10:05:00Z',
            },
            'customer': <String, dynamic>{'id': 7, 'name': 'Nour'},
          },
        ],
      });

      final item = model.data!.first;
      expect(item.id, 42);
      expect(item.arrivedAt, '2026-05-17T10:00:00Z');
      expect(item.workStartedAt, '2026-05-17T10:05:00Z');
      expect(item.customer?.name, 'Nour');
    });
  });
}
