import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_work_timer_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderWorkTimerHelper.resolveWorkerHours', () {
    test('prefers assignment hours over booking total hours', () {
      expect(
        OrderWorkTimerHelper.resolveWorkerHours(
          assignmentHours: 3,
          totalHours: 7.5,
          estimatedHours: 7.5,
        ),
        3,
      );
    });

    test('falls back to totalHours when assignment hours are missing', () {
      expect(
        OrderWorkTimerHelper.resolveWorkerHours(
          assignmentHours: null,
          totalHours: 7.5,
          estimatedHours: 4,
        ),
        7.5,
      );
    });

    test('falls back to estimatedHours when totalHours is zero', () {
      expect(
        OrderWorkTimerHelper.resolveWorkerHours(
          assignmentHours: 0,
          totalHours: 0,
          estimatedHours: 4,
        ),
        4,
      );
    });

    test('originalBookingDuration uses assignment hours', () {
      expect(
        OrderWorkTimerHelper.originalBookingDuration(
          assignmentHours: 2.5,
          totalHours: 7.5,
          estimatedHours: 7.5,
        ),
        const Duration(minutes: 150),
      );
    });
  });
}
