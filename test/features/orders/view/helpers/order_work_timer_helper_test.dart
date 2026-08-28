import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_work_timer_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderWorkTimerHelper', () {
    test('uses the worker assignment duration before booking estimates', () {
      expect(
        OrderWorkTimerHelper.originalBookingDuration(
          assignmentHours: 1.5,
          totalHours: 2,
          estimatedHours: 3,
        ),
        const Duration(minutes: 90),
      );
    });

    test('starts an original session at the supplied work-start time', () {
      final start = DateTime(2026, 7, 1, 9);
      final session = OrderWorkTimerHelper.startOriginalSession(
        now: start,
        maxDuration: const Duration(minutes: 90),
      );

      expect(session.sessionStart, start);
      expect(session.maxDuration, const Duration(minutes: 90));
      expect(session.isExtension, isFalse);
      expect(session.elapsedAt(DateTime(2026, 7, 1, 8, 59)), Duration.zero);
      expect(session.isFinishedAt(DateTime(2026, 7, 1, 10, 30)), isTrue);
    });

    test('uses the latest accepted extension as a distinct timer session', () {
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

      final session = OrderWorkTimerHelper.startExtensionSession(
        now: DateTime(2026, 7, 1, 11, 10),
        seed: seed,
      );
      expect(session.sessionKey, 'extension:8:60');
      expect(session.maxDuration, const Duration(minutes: 60));
      expect(session.isExtension, isTrue);
    });

    test('ignores rejected extensions when totaling accepted extra time', () {
      expect(
        OrderWorkTimerHelper.totalAcceptedExtensionMinutes(const <dynamic>[
          <String, dynamic>{
            'response_status': 'rejected',
            'approved_minutes': 60,
          },
          <String, dynamic>{
            'response_status': 'accepted',
            'approved_minutes': 45,
          },
        ]),
        45,
      );
    });
  });
}
