import 'package:dllni_cleaninig_owner_app/features/orders/data/models/supervised_worker_booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supervised worker parses complete booking-level tasks without materials', () {
    final booking = SupervisedWorkerBooking.fromJson({
      'data': {
        'id': 44,
        'bookingNumber': 'TEAM-44',
        'serviceType': 'supervised_team',
        'status': 'in_progress',
        'scheduledDate': '2026-10-17',
        'scheduledTime': '10:00',
        'supervisor': {'id': 2, 'name': 'مشرف الفريق'},
        'tasks': [
          {
            'id': 1,
            'title': 'غرفة النوم',
            'cleaningMode': 'deep',
            'roomSize': 'medium',
          },
          {
            'id': 2,
            'title': 'الحمام',
            'cleaningMode': 'regular',
            'roomSize': 'small',
          },
        ],
        'specializedServices': [
          {'id': 7, 'name': 'تنظيف الكنب', 'quantity': 2, 'dirtinessLevel': 'heavy'},
        ],
        'allowedActions': ['view', 'sos'],
      },
    });

    expect(booking.id, 44);
    expect(booking.supervisorName, 'مشرف الفريق');
    expect(booking.tasks, hasLength(2));
    expect(booking.tasks.first['cleaningMode'], 'deep');
    expect(booking.specializedServices.single['name'], 'تنظيف الكنب');
  });

  test('legacy open_count cannot be treated as supervisor-managed service', () {
    expect(
      () => SupervisedWorkerBooking.fromJson({
        'data': {'id': 1, 'serviceType': 'standard', 'tasks': []},
      }),
      throwsFormatException,
    );
  });

  test('invalid body is rejected, not represented as an empty real order', () {
    expect(
      () => SupervisedWorkerBooking.fromJson({'data': {}}),
      throwsFormatException,
    );
  });
}
