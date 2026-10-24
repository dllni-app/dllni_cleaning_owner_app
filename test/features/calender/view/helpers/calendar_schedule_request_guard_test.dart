import 'package:dllni_cleaninig_owner_app/features/calender/view/helpers/calendar_schedule_request_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarScheduleRequestGuard', () {
    test('a prior booking response cannot replace a newer booking', () {
      final guard = CalendarScheduleRequestGuard();
      final prior = guard.begin(101);
      final current = guard.begin(202);

      expect(guard.isCurrent(generation: prior, bookingId: 101), isFalse);
      expect(guard.isCurrent(generation: current, bookingId: 202), isTrue);
    });

    test('only the latest request for the same booking is accepted', () {
      final guard = CalendarScheduleRequestGuard();
      final prior = guard.begin(303);
      final current = guard.begin(303);

      expect(guard.isCurrent(generation: prior, bookingId: 303), isFalse);
      expect(guard.isCurrent(generation: current, bookingId: 303), isTrue);
    });

    test('invalidated responses cannot populate a disposed card', () {
      final guard = CalendarScheduleRequestGuard();
      final request = guard.begin(404);
      guard.invalidate();

      expect(guard.isCurrent(generation: request, bookingId: 404), isFalse);
    });

    test('even the current generation must match the booking identity', () {
      final guard = CalendarScheduleRequestGuard();
      final request = guard.begin(505);

      expect(guard.isCurrent(generation: request, bookingId: 506), isFalse);
      expect(guard.isCurrent(generation: request, bookingId: 505), isTrue);
    });

    test('a schedule for another booking is rejected before display', () {
      final guard = CalendarScheduleRequestGuard();
      final request = guard.begin(606);

      expect(
        guard.acceptsResponse(
          generation: request,
          bookingId: 606,
          responseBookingId: 607,
        ),
        isFalse,
      );
      expect(
        guard.acceptsResponse(
          generation: request,
          bookingId: 606,
          responseBookingId: 606,
        ),
        isTrue,
      );
    });

    test('a schedule missing its booking identity is rejected', () {
      final guard = CalendarScheduleRequestGuard();
      final request = guard.begin(707);

      expect(
        guard.acceptsResponse(
          generation: request,
          bookingId: 707,
          responseBookingId: null,
        ),
        isFalse,
      );
    });

    test('a refreshed DTO invalidates the in-flight same-booking response', () {
      final guard = CalendarScheduleRequestGuard();
      final beforeRefresh = guard.begin(808);
      guard.invalidate();
      final afterRefresh = guard.begin(808);

      expect(
        guard.acceptsResponse(
          generation: beforeRefresh,
          bookingId: 808,
          responseBookingId: 808,
        ),
        isFalse,
      );
      expect(
        guard.acceptsResponse(
          generation: afterRefresh,
          bookingId: 808,
          responseBookingId: 808,
        ),
        isTrue,
      );
    });
  });
}
