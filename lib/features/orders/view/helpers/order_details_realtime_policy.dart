import '../../../../core/realtime/cleaning_realtime_contract.dart';
import '../../data/models/cleaning_booking_status.dart';
import 'order_lifecycle_policy.dart';

/// Resolves local lifecycle patches from realtime payloads on order details.
class OrderDetailsRealtimePolicy {
  OrderDetailsRealtimePolicy._();

  /// Patch to apply when [CleaningRealtimeContract.arrivalVerified] is received.
  ///
  /// Backend should send `status: awaiting_worker_start_confirmation` after
  /// customer code verification. If the status is omitted, keep the worker on
  /// the start-confirmation step instead of starting work optimistically.
  static ({
    String status,
    String? arrivedAt,
    String? workStartedAt,
  })? patchFromArrivalVerified({
    required String? currentStatus,
    required Map<String, dynamic> payload,
  }) {
    final explicitStatus = CleaningRealtimeContract.extractTrackingStatus(
      payload,
    );
    final timestamps = CleaningRealtimeContract.extractLifecycleTimestamps(
      payload,
    );

    if (explicitStatus != null &&
        OrderLifecyclePolicy.shouldPreferIncomingStatus(
          currentStatus,
          explicitStatus,
        )) {
      return (
        status: explicitStatus,
        arrivedAt: timestamps.arrivedAt,
        workStartedAt: timestamps.workStartedAt,
      );
    }

    if (explicitStatus == null &&
        OrderLifecyclePolicy.shouldPreferIncomingStatus(
          currentStatus,
          CleaningBookingStatus.awaitingWorkerStartConfirmation,
        )) {
      return (
        status: CleaningBookingStatus.awaitingWorkerStartConfirmation,
        arrivedAt: timestamps.arrivedAt,
        workStartedAt: timestamps.workStartedAt,
      );
    }

    return null;
  }

  /// Patch to apply when tracking status is present on a tracking update event.
  /// Worker-channel events may include multiple bookings; only handle the one
  /// currently open in order details when [extractBookingId] is present.
  static bool shouldHandleWorkerChannelEvent({
    required int currentBookingId,
    required Map<String, dynamic> payload,
  }) {
    final payloadBookingId = CleaningRealtimeContract.extractBookingId(payload);
    if (payloadBookingId == null) return true;
    return payloadBookingId == currentBookingId;
  }

  static ({
    String status,
    String? arrivedAt,
    String? workStartedAt,
  })? patchFromTrackingUpdate({
    required String? currentStatus,
    required Map<String, dynamic> payload,
  }) {
    final status = CleaningRealtimeContract.extractTrackingStatus(payload);
    if (status == null) return null;
    if (!OrderLifecyclePolicy.shouldPreferIncomingStatus(currentStatus, status)) {
      return null;
    }
    final timestamps = CleaningRealtimeContract.extractLifecycleTimestamps(
      payload,
    );
    return (
      status: status,
      arrivedAt: timestamps.arrivedAt,
      workStartedAt: timestamps.workStartedAt,
    );
  }
}
