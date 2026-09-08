import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/worker_schedule_reconciliation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('worker schedule reconciliation', () {
    test('selects the next valid session and clears removed security state', () {
      final schedule = _schedule(
        sessions: const [
          {'id': 101, 'sequence': 1, 'date': '2026-09-15', 'time': '10:00', 'hours': 2, 'status': 'scheduled'},
          {'id': 103, 'sequence': 3, 'date': '2026-09-17', 'time': '10:00', 'hours': 2, 'status': 'scheduled'},
        ],
        nextSession: const {'id': 103, 'sequence': 3, 'date': '2026-09-17', 'time': '10:00', 'hours': 2, 'status': 'scheduled'},
      );

      final result = reconcileWorkerSchedule(
        schedule: schedule,
        currentSelectedSessionId: 102,
        preferredSessionId: 102,
        securityCodeSessionId: 102,
        bookingId: 501,
        trackedBookingId: null,
        trackedSessionId: null,
      );

      expect(result.selectedSessionId, 103);
      expect(result.clearSecurityCode, isTrue);
      expect(result.stopLocationTracking, isFalse);
    });

    test('clears selection and security state when no scoped sessions remain', () {
      final schedule = _schedule(sessions: const []);

      final result = reconcileWorkerSchedule(
        schedule: schedule,
        currentSelectedSessionId: 102,
        preferredSessionId: 102,
        securityCodeSessionId: 102,
        bookingId: 501,
        trackedBookingId: null,
        trackedSessionId: null,
      );

      expect(result.selectedSessionId, isNull);
      expect(result.clearSecurityCode, isTrue);
      expect(result.stopLocationTracking, isFalse);
    });

    test('stops location tracking when the actively tracked session is removed', () {
      final schedule = _schedule(
        sessions: const [
          {'id': 101, 'sequence': 1, 'date': '2026-09-15', 'time': '10:00', 'hours': 2, 'status': 'scheduled'},
        ],
      );

      final result = reconcileWorkerSchedule(
        schedule: schedule,
        currentSelectedSessionId: 101,
        preferredSessionId: 101,
        securityCodeSessionId: null,
        bookingId: 501,
        trackedBookingId: 501,
        trackedSessionId: 102,
      );

      expect(result.selectedSessionId, 101);
      expect(result.stopLocationTracking, isTrue);
    });

    test('keeps a valid selected and tracked session when a sibling changes', () {
      final schedule = _schedule(
        sessions: const [
          {'id': 103, 'sequence': 3, 'date': '2026-09-17', 'time': '10:00', 'hours': 2, 'status': 'in_progress'},
        ],
      );

      final result = reconcileWorkerSchedule(
        schedule: schedule,
        currentSelectedSessionId: 103,
        preferredSessionId: 101,
        securityCodeSessionId: 103,
        bookingId: 501,
        trackedBookingId: 501,
        trackedSessionId: 103,
      );

      expect(result.selectedSessionId, 103);
      expect(result.clearSecurityCode, isFalse);
      expect(result.stopLocationTracking, isFalse);
    });
  });
}

WorkerBookingScheduleModel _schedule({
  required List<Map<String, dynamic>> sessions,
  Map<String, dynamic>? nextSession,
}) {
  final result = workerMultiDayBookingEnvelopeFromJson({
    'data': {
      'id': 501,
      'schedule': {
        'mode': 'multi_day',
        'bookingDaysCount': 4,
        'daysCount': sessions.length,
        'sessions': sessions,
        'nextSession': nextSession,
      },
    },
  });

  return result.schedule!;
}
