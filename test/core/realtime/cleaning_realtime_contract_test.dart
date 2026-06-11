import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CleaningRealtimeContract', () {
    test('normalizes security-code and arrival aliases', () {
      expect(
        CleaningRealtimeContract.normalizeEventName('SecurityCodeIssued'),
        CleaningRealtimeContract.awaitingStartVerification,
      );
      expect(
        CleaningRealtimeContract.normalizeEventName(
          'cleaning_order.security_code_issued',
        ),
        CleaningRealtimeContract.awaitingStartVerification,
      );
      expect(
        CleaningRealtimeContract.normalizeEventName('worker_arrived'),
        CleaningRealtimeContract.workerArrived,
      );
      expect(
        CleaningRealtimeContract.normalizeEventName(
          'cleaning_order.arrival_verified',
        ),
        CleaningRealtimeContract.arrivalVerified,
      );
      expect(
        CleaningRealtimeContract.normalizeEventName('arrival_verified'),
        CleaningRealtimeContract.arrivalVerified,
      );
      expect(
        CleaningRealtimeContract.normalizeEventName(
          'arrival_verification_requested',
        ),
        CleaningRealtimeContract.awaitingStartVerification,
      );
      expect(
        CleaningRealtimeContract.normalizeEventName(
          'cleaning_order.awaiting_worker_start_confirmation',
        ),
        CleaningRealtimeContract.awaitingWorkerStartConfirmation,
      );
    });

    test('extracts booking id from nested payload aliases', () {
      expect(
        CleaningRealtimeContract.extractBookingId(const <String, dynamic>{
          'cleaning_order_id': 42,
        }),
        42,
      );
      expect(
        CleaningRealtimeContract.extractBookingId(const <String, dynamic>{
          'tracking': <String, dynamic>{'cleaning_order_id': 19},
        }),
        19,
      );
      expect(
        CleaningRealtimeContract.extractBookingId(const <String, dynamic>{
          'cleaning_order': <String, dynamic>{'id': 63},
        }),
        63,
      );
      expect(
        CleaningRealtimeContract.extractBookingId(const <String, dynamic>{
          'data': <String, dynamic>{
            'cleaning_booking': <String, dynamic>{'id': 94},
          },
        }),
        94,
      );
    });

    test('extracts tracking status from nested booking maps', () {
      expect(
        CleaningRealtimeContract.extractTrackingStatus(const <String, dynamic>{
          'cleaning_booking': <String, dynamic>{
            'status': CleaningBookingStatus.inProgress,
          },
        }),
        CleaningBookingStatus.inProgress,
      );
      expect(
        CleaningRealtimeContract.extractTrackingStatus(const <String, dynamic>{
          'data': <String, dynamic>{
            'tracking': <String, dynamic>{
              'status': CleaningBookingStatus.awaitingStartVerification,
            },
          },
        }),
        CleaningBookingStatus.awaitingStartVerification,
      );
    });

    test('extracts lifecycle timestamps from nested payload aliases', () {
      final timestamps = CleaningRealtimeContract.extractLifecycleTimestamps(
        const <String, dynamic>{
          'arrived_at': '2026-05-17T10:00:00Z',
          'work_started_at': '2026-05-17T10:05:00Z',
        },
      );
      expect(timestamps.arrivedAt, '2026-05-17T10:00:00Z');
      expect(timestamps.workStartedAt, '2026-05-17T10:05:00Z');

      final nested = CleaningRealtimeContract.extractLifecycleTimestamps(
        const <String, dynamic>{
          'data': <String, dynamic>{
            'cleaning_order': <String, dynamic>{
              'arrivedAt': '2026-05-17T11:00:00Z',
              'workStartedAt': '2026-05-17T11:05:00Z',
            },
          },
        },
      );
      expect(nested.arrivedAt, '2026-05-17T11:00:00Z');
      expect(nested.workStartedAt, '2026-05-17T11:05:00Z');
    });

    test('treats arrival verified as lifecycle refresh event', () {
      expect(
        CleaningRealtimeContract.isLifecycleRefreshEvent('ArrivalVerified'),
        isTrue,
      );
      expect(
        CleaningRealtimeContract.isLifecycleRefreshEvent(
          'cleaning_order.arrival_verified',
        ),
        isTrue,
      );
      expect(
        CleaningRealtimeContract.isLifecycleRefreshEvent(
          'cleaning_order.awaiting_worker_start_confirmation',
        ),
        isTrue,
      );
    });
  });
}
