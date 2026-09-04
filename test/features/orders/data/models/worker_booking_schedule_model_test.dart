import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses multi-day worker schedule capability flags and assignment state',
    () {
      final result = workerMultiDayBookingEnvelopeFromJson({
        'data': {
          'id': 501,
          'bookingNumber': 'CLN-202609-000501',
          'status': 'partially_completed',
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
                'canStartTravel': true,
                'canArrive': false,
                'canStartWork': false,
                'canComplete': false,
                'canExtend': false,
                'canCancel': true,
                'pricing': {
                  'totalPrice': 6500,
                  'travelDistanceKm': 2.8,
                  'currency': 'SYP',
                },
                'workerAssignmentState': {
                  'id': 7001,
                  'parentAssignmentId': 7000,
                  'workerId': 28,
                  'workerName': 'Worker Name',
                  'status': 'accepted_waiting_for_order_start',
                  'serviceShareAmount': 5000,
                  'travelFee': 500,
                  'adminMarginAmount': 300,
                  'workerAmount': 5200,
                  'currency': 'SYP',
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

      final session = result.schedule?.sessionById(102);
      expect(result.bookingId, 501);
      expect(result.status, 'partially_completed');
      expect(result.schedule?.isMultiDay, isTrue);
      expect(result.schedule?.daysCount, 3);
      expect(result.schedule?.completedDaysCount, 1);
      expect(result.schedule?.nextSession?.id, 102);
      expect(session?.isToday, isTrue);
      expect(session?.canStartTravel, isTrue);
      expect(session?.canCancel, isTrue);
      expect(session?.workerAssignmentState?.workerId, 28);
      expect(session?.workerAssignmentState?.workerAmount, 5200);
      expect(session?.assignment?.workerId, 28);
      expect(session?.pricing?.travelDistanceKm, 2.8);
    },
  );

  test('keeps compatibility with legacy myAssignment shape', () {
    final result = workerMultiDayBookingEnvelopeFromJson({
      'data': {
        'id': 501,
        'schedule': {
          'mode': 'multi_day',
          'daysCount': 2,
          'sessions': [
            {
              'id': 102,
              'sequence': 2,
              'date': '2026-09-12',
              'time': '17:30',
              'hours': 5,
              'status': 'worker_assigned',
              'myAssignment': {
                'id': 7001,
                'workerId': 28,
                'status': 'accepted',
                'grossAmount': 6000,
              },
            },
          ],
        },
      },
    });

    expect(result.schedule?.sessionById(102)?.assignment?.workerId, 28);
    expect(result.schedule?.sessionById(102)?.assignment?.grossAmount, 6000);
  });

  test('action response parses session independently from parent', () {
    final result = workerMultiDayBookingEnvelopeFromJson({
      'order': {
        'id': 501,
        'status': 'in_progress',
        'schedule': {'mode': 'multi_day', 'daysCount': 2, 'sessions': []},
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
