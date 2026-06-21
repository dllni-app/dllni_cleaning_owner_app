import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/worker_realtime_orders_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerRealtimeOrdersSync', () {
    test('ignores worker location updates', () {
      expect(
        WorkerRealtimeOrdersSync.shouldProcessWorkerEvent(
          eventName: CleaningRealtimeContract.workerLocationUpdated,
          payload: const <String, dynamic>{'cleaningBookingId': 12},
        ),
        isFalse,
      );
    });

    test('processes pending tracking updates with booking id', () {
      expect(
        WorkerRealtimeOrdersSync.shouldProcessWorkerEvent(
          eventName: CleaningRealtimeContract.trackingUpdated,
          payload: const <String, dynamic>{
            'tracking': <String, dynamic>{
              'cleaningBookingId': 12,
              'status': 'pending',
            },
          },
        ),
        isTrue,
      );
    });

    test('does not prefer list refetch when tracking update has booking id', () {
      expect(
        WorkerRealtimeOrdersSync.prefersListRefetch(
          eventName: CleaningRealtimeContract.trackingUpdated,
          payload: const <String, dynamic>{'cleaningBookingId': 12},
        ),
        isFalse,
      );
    });

    test('prefers list refetch for lifecycle events', () {
      expect(
        WorkerRealtimeOrdersSync.prefersListRefetch(
          eventName: CleaningRealtimeContract.workerArrived,
          payload: const <String, dynamic>{'cleaningBookingId': 12},
        ),
        isTrue,
      );
    });
  });
}
