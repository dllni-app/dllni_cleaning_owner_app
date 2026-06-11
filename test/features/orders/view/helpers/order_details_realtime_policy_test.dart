import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_details_realtime_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDetailsRealtimePolicy', () {
    test(
      'advances to in_progress when arrival verified payload omits status',
      () {
        final patch = OrderDetailsRealtimePolicy.patchFromArrivalVerified(
          currentStatus: CleaningBookingStatus.awaitingStartVerification,
          payload: const <String, dynamic>{
            'bookingId': 42,
            'arrivedAt': '2026-05-17T10:00:00Z',
          },
        );

        expect(patch, isNotNull);
        expect(patch!.status, CleaningBookingStatus.inProgress);
        expect(patch.arrivedAt, '2026-05-17T10:00:00Z');
        expect(
          OrderLifecyclePolicy.detailsStepForStatus(patch.status),
          3,
        );
      },
    );

    test('uses explicit status when arrival verified payload includes it', () {
      final patch = OrderDetailsRealtimePolicy.patchFromArrivalVerified(
        currentStatus: CleaningBookingStatus.awaitingStartVerification,
        payload: const <String, dynamic>{
          'status': CleaningBookingStatus.inProgress,
          'work_started_at': '2026-05-17T10:05:00Z',
        },
      );

      expect(patch, isNotNull);
      expect(patch!.status, CleaningBookingStatus.inProgress);
      expect(patch.workStartedAt, '2026-05-17T10:05:00Z');
    });

    test('does not downgrade lifecycle on arrival verified', () {
      final patch = OrderDetailsRealtimePolicy.patchFromArrivalVerified(
        currentStatus: CleaningBookingStatus.inProgress,
        payload: const <String, dynamic>{
          'status': CleaningBookingStatus.awaitingStartVerification,
        },
      );

      expect(patch, isNull);
    });

    test('patchFromTrackingUpdate applies status from tracking payload', () {
      final patch = OrderDetailsRealtimePolicy.patchFromTrackingUpdate(
        currentStatus: CleaningBookingStatus.awaitingStartVerification,
        payload: const <String, dynamic>{
          'tracking': <String, dynamic>{
            'status': CleaningBookingStatus.inProgress,
          },
        },
      );

      expect(patch, isNotNull);
      expect(patch!.status, CleaningBookingStatus.inProgress);
    });

    test(
      'shouldHandleWorkerChannelEvent accepts matching booking id payloads',
      () {
        expect(
          OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(
            currentBookingId: 42,
            payload: const <String, dynamic>{'bookingId': 42},
          ),
          isTrue,
        );
        expect(
          OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(
            currentBookingId: 42,
            payload: const <String, dynamic>{
              'arrivedAt': '2026-05-17T10:00:00Z',
            },
          ),
          isTrue,
        );
      },
    );

    test(
      'shouldHandleWorkerChannelEvent rejects other booking ids on worker channel',
      () {
        expect(
          OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(
            currentBookingId: 42,
            payload: const <String, dynamic>{'bookingId': 99},
          ),
          isFalse,
        );
        expect(
          OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(
            currentBookingId: 42,
            payload: const <String, dynamic>{
              'cleaning_booking': <String, dynamic>{'id': 77},
            },
          ),
          isFalse,
        );
      },
    );

    test(
      'worker-channel arrival verified without status advances to mission step',
      () {
        final handles = OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(
          currentBookingId: 42,
          payload: const <String, dynamic>{'bookingId': 42},
        );
        expect(handles, isTrue);

        final patch = OrderDetailsRealtimePolicy.patchFromArrivalVerified(
          currentStatus: CleaningBookingStatus.awaitingStartVerification,
          payload: const <String, dynamic>{
            'bookingId': 42,
            'arrivedAt': '2026-05-17T10:00:00Z',
          },
        );

        expect(patch?.status, CleaningBookingStatus.inProgress);
        expect(OrderLifecyclePolicy.detailsStepForStatus(patch!.status), 3);
      },
    );
  });
}
