import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_work_timer_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderWorkTimerHelper', () {
    test('uses scheduled time when work starts before service time', () {
      final session = OrderWorkTimerHelper.resolve(
        scheduledDate: '2026-07-01',
        scheduledTime: '09:00:00',
        workStartedAt: '2026-07-01T08:30:00',
        arrivedAt: null,
        totalHours: 1.5,
        estimatedHours: null,
        timeWarnings: const <dynamic>[],
      );

      expect(session, isNotNull);
      expect(session!.startedAt, DateTime(2026, 7, 1, 9));
      expect(session.duration, const Duration(minutes: 90));
      expect(session.expectedFinishAt, DateTime(2026, 7, 1, 10, 30));
      expect(session.isOvertime, isFalse);
    });

    test('uses actual work start when worker starts after scheduled time', () {
      final session = OrderWorkTimerHelper.resolve(
        scheduledDate: '2026-07-01',
        scheduledTime: '09:00:00',
        workStartedAt: '2026-07-01T09:05:00',
        arrivedAt: null,
        totalHours: 1.5,
        estimatedHours: null,
        timeWarnings: const <dynamic>[],
      );

      expect(session, isNotNull);
      expect(session!.startedAt, DateTime(2026, 7, 1, 9, 5));
      expect(session.expectedFinishAt, DateTime(2026, 7, 1, 10, 35));
    });

    test('accepted overtime starts a new timer session with approved minutes', () {
      final session = OrderWorkTimerHelper.resolve(
        scheduledDate: '2026-07-01',
        scheduledTime: '09:00:00',
        workStartedAt: '2026-07-01T09:00:00',
        arrivedAt: null,
        totalHours: 1.5,
        estimatedHours: null,
        timeWarnings: const <dynamic>[
          <String, dynamic>{
            'id': 7,
            'worker_response': 'accepted',
            'additional_minutes': 45,
            'worker_responded_at': '2026-07-01T10:31:00',
          },
        ],
      );

      expect(session, isNotNull);
      expect(session!.isOvertime, isTrue);
      expect(session.startedAt, DateTime(2026, 7, 1, 10, 31));
      expect(session.duration, const Duration(minutes: 45));
      expect(session.expectedFinishAt, DateTime(2026, 7, 1, 11, 16));
      expect(session.sessionKey, contains('extension:7'));
    });

    test('uses latest accepted overtime warning when several exist', () {
      final session = OrderWorkTimerHelper.resolve(
        scheduledDate: '2026-07-01',
        scheduledTime: '09:00:00',
        workStartedAt: '2026-07-01T09:00:00',
        arrivedAt: null,
        totalHours: 1.5,
        estimatedHours: null,
        timeWarnings: const <dynamic>[
          <String, dynamic>{
            'id': 7,
            'worker_response': 'accepted',
            'additional_minutes': 30,
            'worker_responded_at': '2026-07-01T10:31:00',
          },
          <String, dynamic>{
            'id': 8,
            'responseStatus': 'accepted',
            'approvedMinutes': 60,
            'updatedAt': '2026-07-01T11:10:00',
          },
        ],
      );

      expect(session, isNotNull);
      expect(session!.sessionKey, contains('extension:8'));
      expect(session.duration, const Duration(minutes: 60));
      expect(session.expectedFinishAt, DateTime(2026, 7, 1, 12, 10));
    });
  });
}
