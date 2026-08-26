import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses multi-day worker schedule and session assignment', () {
    final result = workerMultiDayBookingEnvelopeFromJson({
      'data': {
        'id': 501,
        'bookingNumber': 'CLN-202609-000501',
        'status': 'worker_assigned',
        'schedule': {
          'mode': 'multi_day',
          'daysCount': 3,
          'completedDaysCount': 1,
          'cancelledDaysCount': 0,
          'remainingDaysCount': 2,
          'totalHours': 12,
          'nextSession': {
            'id': 102,
            'sequence': 2,
            'date': '2026-09-12',
            'time': '17:30',
            'hours': 5,
            'status': 'worker_assigned',
          },
          'sessions': [
            {
              'id': 101,
              'sequence': 1,
              'date': '2026-09-10',
              'time': '18:00',
              'hours': 4,
              'status': 'completed',
            },
            {
              'id': 102,
              'sequence': 2,
              'date': '2026-09-12',
              'time': '17:30',
              'hours': 5,
              'status': 'worker_assigned',
              'isToday': true,
              'myAssignment': {
                'id': 7001,
                'workerId': 28,
                'status': 'accepted',
                'grossAmount': 6000,
              },
            },
            {
              'id': 103,
              'sequence': 3,
              'date': '2026-09-15',
              'time': '18:00',
              'hours': 3,
              'status': 'scheduled',
            },
          ],
        },
      },
    });

    expect(result.bookingId, 501);
    expect(result.schedule?.isMultiDay, isTrue);
    expect(result.schedule?.daysCount, 3);
    expect(result.schedule?.completedDaysCount, 1);
    expect(result.schedule?.nextSession?.id, 102);
    expect(result.schedule?.sessionById(102)?.isToday, isTrue);
    expect(result.schedule?.sessionById(102)?.assignment?.workerId, 28);
    expect(result.schedule?.sessionById(102)?.assignment?.grossAmount, 6000);
  });

  test('action response parses session independently from parent', () {
    final result = workerMultiDayBookingEnvelopeFromJson({
      'order': {
        'id': 501,
        'status': 'in_progress',
        'schedule': {
          'mode': 'multi_day',
          'daysCount': 2,
          'sessions': [],
        },
      },
      'session': {
        'id': 1002,
        'sequence': 2,
        'date': '2026-09-12',
        'time': '17:30',
        'hours': 5,
        'status': 'in_progress',
        'workStartedAt': '2026-09-12T17:35:00+03:00',
      },
    });

    expect(result.status, 'in_progress');
    expect(result.session?.id, 1002);
    expect(result.session?.isInProgress, isTrue);
    expect(result.session?.workStartedAt, isNotNull);
  });
}
