import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_work_timer_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderWorkTimerHelper', () {
    test('starts the original timer from the current work session time', () {
      final duration = OrderWorkTimerHelper.originalBookingDuration(
        totalHours: 1.5,
        estimatedHours: null,
      );
      expect(duration, const Duration(minutes: 90));

      final startedAt = DateTime(2026, 7, 1, 9);
      final session = OrderWorkTimerHelper.startOriginalSession(
        now: startedAt,
        maxDuration: duration!,
      );

      expect(session.sessionStart, startedAt);
      expect(session.maxDuration, const Duration(minutes: 90));
      expect(session.isExtension, isFalse);
      expect(session.isFinishedAt(DateTime(2026, 7, 1, 10, 29)), isFalse);
      expect(session.isFinishedAt(DateTime(2026, 7, 1, 10, 30)), isTrue);
    });

    test('prefers worker assignment hours over booking estimates', () {
      expect(
        OrderWorkTimerHelper.resolveWorkerHours(
          assignmentHours: 2,
          totalHours: 1.5,
          estimatedHours: 3,
        ),
        2,
      );
      expect(
        OrderWorkTimerHelper.originalBookingDuration(
          assignmentHours: 2,
          totalHours: 1.5,
          estimatedHours: 3,
        ),
        const Duration(hours: 2),
      );
    });

    test('accepted overtime starts a new timer session with approved minutes', () {
      final seed = OrderWorkTimerHelper.latestAcceptedExtensionSeed(
        const <dynamic>[
          <String, dynamic>{
            'id': 7,
            'worker_response': 'accepted',
            'additional_minutes': 45,
            'worker_responded_at': '2026-07-01T10:31:00',
          },
        ],
      );

      expect(seed, isNotNull);
      expect(seed!.id, 7);
      expect(seed.minutes, 45);

      final startedAt = DateTime(2026, 7, 1, 10, 31);
      final session = OrderWorkTimerHelper.startExtensionSession(
        now: startedAt,
        seed: seed,
      );
      expect(session.isExtension, isTrue);
      expect(session.sessionStart, startedAt);
      expect(session.maxDuration, const Duration(minutes: 45));
      expect(session.sessionKey, 'extension:7:45');
    });

    test('uses latest accepted overtime warning when several exist', () {
      final seed = OrderWorkTimerHelper.latestAcceptedExtensionSeed(
        const <dynamic>[
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

      expect(seed, isNotNull);
      expect(seed!.id, 8);
      expect(seed.minutes, 60);
      expect(seed.sessionKey, 'extension:8:60');
    });
  });
}
