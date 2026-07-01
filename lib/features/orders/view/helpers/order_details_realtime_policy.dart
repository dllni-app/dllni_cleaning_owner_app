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
    final explicitStatus = CleaningRealtimeContract.extractTrackingStatus(payload);
    final timestamps = CleaningRealtimeContract.extractLifecycleTimestamps(payload);

    if (explicitStatus != null && OrderLifecyclePolicy.shouldPreferIncomingStatus(currentStatus, explicitStatus)) {
      return (status: explicitStatus, arrivedAt: timestamps.arrivedAt, workStartedAt: timestamps.workStartedAt);
    }

    if (explicitStatus == null && OrderLifecyclePolicy.shouldPreferIncomingStatus(currentStatus, CleaningBookingStatus.awaitingWorkerStartConfirmation)) {
      return (status: CleaningBookingStatus.awaitingWorkerStartConfirmation, arrivedAt: timestamps.arrivedAt, workStartedAt: timestamps.workStartedAt);
    }

    return null;
  }

  /// Worker-channel events are shared for a worker, so details screens must only
  /// handle payloads that explicitly belong to the currently open booking.
  static bool shouldHandleWorkerChannelEvent({
    required int currentBookingId,
    required Map<String, dynamic> payload,
  }) {
    final payloadBookingId = CleaningRealtimeContract.extractBookingId(payload);
    if (payloadBookingId == null) return false;
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
    if (!OrderLifecyclePolicy.shouldPreferIncomingStatus(currentStatus, status)) return null;
    final timestamps = CleaningRealtimeContract.extractLifecycleTimestamps(payload);
    return (status: status, arrivedAt: timestamps.arrivedAt, workStartedAt: timestamps.workStartedAt);
  }

  static ({
    String status,
    String? message,
    int? warningId,
    String? decision,
  })? patchFromCompletionDecision({
    required String? currentStatus,
    required Map<String, dynamic> payload,
  }) {
    final unwrapped = CleaningRealtimeContract.unwrapPayload(payload);
    final decision = CleaningRealtimeContract.extractDecision(unwrapped);
    if (decision == null || decision.isEmpty) return null;

    final resolvedStatus = CleaningRealtimeContract.extractTrackingStatus(unwrapped);
    if (resolvedStatus == null || resolvedStatus.isEmpty) return null;

    if (!OrderLifecyclePolicy.shouldApplyRealtimeStatus(currentStatus: currentStatus, incomingStatus: resolvedStatus, decision: decision)) {
      return null;
    }

    return (
      status: resolvedStatus,
      message: CleaningRealtimeContract.extractDecisionMessage(unwrapped),
      warningId: CleaningRealtimeContract.extractWarningId(unwrapped),
      decision: decision,
    );
  }
}
