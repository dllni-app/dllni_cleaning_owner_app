import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_operational_details.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_open_time_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderOpenTimePresentation', () {
    test(
      'uses the server work-start timestamp for active elapsed presentation',
      () {
        final presentation = OrderOpenTimePresentation.resolve(
          openTime: const CleaningOpenTimeDetails(
            isOpenTime: true,
            workStartedAt: '2026-09-06T10:00:00Z',
          ),
          now: DateTime.utc(2026, 9, 6, 10, 37, 12),
        );

        expect(presentation.elapsed, const Duration(minutes: 37, seconds: 12));
        expect(presentation.isFinal, isFalse);
      },
    );

    test(
      'uses the finalized server duration instead of recalculating billing',
      () {
        final presentation = OrderOpenTimePresentation.resolve(
          openTime: const CleaningOpenTimeDetails(
            isOpenTime: true,
            workStartedAt: '2026-09-06T10:00:00Z',
            workFinishedAt: '2026-09-06T10:45:00Z',
            actualDurationMinutes: 44,
            billableDurationMinutes: 60,
            isFinalized: true,
          ),
          now: DateTime.utc(2026, 9, 6, 12),
        );

        expect(presentation.elapsed, const Duration(minutes: 44));
        expect(presentation.isFinal, isTrue);
      },
    );

    test('clamps an invalid future server start to zero elapsed time', () {
      final presentation = OrderOpenTimePresentation.resolve(
        openTime: const CleaningOpenTimeDetails(
          isOpenTime: true,
          workStartedAt: '2026-09-06T11:00:00Z',
        ),
        now: DateTime.utc(2026, 9, 6, 10),
      );

      expect(presentation.elapsed, Duration.zero);
    });
  });
}
