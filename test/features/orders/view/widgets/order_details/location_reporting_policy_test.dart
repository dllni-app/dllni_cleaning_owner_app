import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/location_reporting_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldReportWorkerLocation', () {
    test('returns true only in worker_assigned with startedTravelAt', () {
      expect(
        shouldReportWorkerLocation(
          status: CleaningBookingStatus.workerAssigned,
          startedTravelAt: '2026-05-17T10:00:00Z',
        ),
        isTrue,
      );
    });

    test('returns false when startedTravelAt is empty', () {
      expect(
        shouldReportWorkerLocation(
          status: CleaningBookingStatus.workerAssigned,
          startedTravelAt: '',
        ),
        isFalse,
      );
    });

    test('returns false when status is outside map stage lifecycle', () {
      expect(
        shouldReportWorkerLocation(
          status: CleaningBookingStatus.awaitingStartVerification,
          startedTravelAt: '2026-05-17T10:00:00Z',
        ),
        isFalse,
      );
    });

    test('returns false when arrivedAt is set even if still worker_assigned', () {
      expect(
        shouldReportWorkerLocation(
          status: CleaningBookingStatus.workerAssigned,
          startedTravelAt: '2026-05-17T10:00:00Z',
          arrivedAt: '2026-05-17T10:30:00Z',
        ),
        isFalse,
      );
    });
  });
}
