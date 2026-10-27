import 'package:dllni_cleaninig_owner_app/features/orders/data/models/supervised_worker_booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses only authenticated worker attendance and server capabilities',
    () {
      final booking = SupervisedWorkerBooking.fromJson({
        'data': {
          'serviceType': 'supervised_team',
          'id': 41,
          'bookingNumber': 'CLN-LINKED-001',
          'status': 'worker_assigned',
          'allowedActions': ['view', 'sos'],
          'myAttendance': {
            'startedTravelAt': '2026-10-26T08:00:00Z',
            'arrivedAt': null,
            'canStartTravel': false,
            'canArrive': true,
          },
        },
      });

      expect(booking.startedTravelAt, '2026-10-26T08:00:00Z');
      expect(booking.arrivedAt, isNull);
      expect(booking.canStartTravel, isFalse);
      expect(booking.canArrive, isTrue);
      expect(booking.allowedActions, ['view', 'sos']);
    },
  );

  test('missing attendance capabilities fail closed', () {
    final booking = SupervisedWorkerBooking.fromJson({
      'data': {
        'serviceType': 'supervised_team',
        'id': 41,
        'allowedActions': ['view'],
      },
    });

    expect(booking.canStartTravel, isFalse);
    expect(booking.canArrive, isFalse);
    expect(booking.startedTravelAt, isNull);
    expect(booking.arrivedAt, isNull);
  });
}
