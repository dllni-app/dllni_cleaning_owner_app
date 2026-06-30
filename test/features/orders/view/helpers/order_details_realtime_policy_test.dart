import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_details_realtime_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDetailsRealtimePolicy', () {
    test('advances to worker start confirmation when arrival verified omits status', () {
      final patch = OrderDetailsRealtimePolicy.patchFromArrivalVerified(
        currentStatus: CleaningBookingStatus.awaitingStartVerification,
        payload: const <String, dynamic>{'bookingId': 42, 'arrivedAt': '2026-05-17T10:00:00Z'},
      );

      expect(patch, isNotNull);
      expect(patch!.status, CleaningBookingStatus.awaitingWorkerStartConfirmation);
      expect(patch.arrivedAt, '2026-05-17T10:00:00Z');
      expect(OrderLifecyclePolicy.detailsStepForStatus(patch.status), 2);
    });

    test('uses explicit status when arrival verified payload includes it', () {
      final patch = OrderDetailsRealtimePolicy.patchFromArrivalVerified(
        currentStatus: CleaningBookingStatus.awaitingStartVerification,
        payload: const <String, dynamic>{
          'status': CleaningBookingStatus.awaitingWorkerStartConfirmation,
          'customer_confirmed_at': '2026-05-17T10:05:00Z',
        },
      );

      expect(patch, isNotNull);
      expect(patch!.status, CleaningBookingStatus.awaitingWorkerStartConfirmation);
      expect(patch.workStartedAt, isNull);
    });

    test('does not downgrade lifecycle on arrival verified', () {
      final patch = OrderDetailsRealtimePolicy.patchFromArrivalVerified(
        currentStatus: CleaningBookingStatus.inProgress,
        payload: const <String, dynamic>{'status': CleaningBookingStatus.awaitingStartVerification},
      );
      expect(patch, isNull);
    });

    test('patchFromTrackingUpdate applies status from tracking payload', () {
      final patch = OrderDetailsRealtimePolicy.patchFromTrackingUpdate(
        currentStatus: CleaningBookingStatus.awaitingStartVerification,
        payload: const <String, dynamic>{'tracking': <String, dynamic>{'status': CleaningBookingStatus.inProgress}},
      );
      expect(patch, isNotNull);
      expect(patch!.status, CleaningBookingStatus.inProgress);
    });

    test('tracking update applies awaiting worker start confirmation status', () {
      final patch = OrderDetailsRealtimePolicy.patchFromTrackingUpdate(
        currentStatus: CleaningBookingStatus.awaitingStartVerification,
        payload: const <String, dynamic>{'tracking': <String, dynamic>{'status': CleaningBookingStatus.awaitingWorkerStartConfirmation}},
      );

      expect(patch, isNotNull);
      expect(patch!.status, CleaningBookingStatus.awaitingWorkerStartConfirmation);
      expect(OrderLifecyclePolicy.detailsStepForStatus(patch.status), 2);
    });

    test('shouldHandleWorkerChannelEvent accepts matching booking id payloads only', () {
      expect(
        OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(currentBookingId: 42, payload: const <String, dynamic>{'bookingId': 42}),
        isTrue,
      );
      expect(
        OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(currentBookingId: 42, payload: const <String, dynamic>{'arrivedAt': '2026-05-17T10:00:00Z'}),
        isFalse,
      );
    });

    test('shouldHandleWorkerChannelEvent rejects other booking ids on worker channel', () {
      expect(
        OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(currentBookingId: 42, payload: const <String, dynamic>{'bookingId': 99}),
        isFalse,
      );
      expect(
        OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(
          currentBookingId: 42,
          payload: const <String, dynamic>{'cleaning_booking': <String, dynamic>{'id': 77}},
        ),
        isFalse,
      );
    });

    test('worker-channel arrival verified without booking id is ignored', () {
      final handles = OrderDetailsRealtimePolicy.shouldHandleWorkerChannelEvent(
        currentBookingId: 42,
        payload: const <String, dynamic>{'arrivedAt': '2026-05-17T10:00:00Z'},
      );
      expect(handles, isFalse);
    });
  });
}
