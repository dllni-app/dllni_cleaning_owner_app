import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';

class WorkerScheduleReconciliationResult {
  const WorkerScheduleReconciliationResult({
    required this.selectedSessionId,
    required this.clearSecurityCode,
    required this.stopLocationTracking,
  });

  final int? selectedSessionId;
  final bool clearSecurityCode;
  final bool stopLocationTracking;
}

WorkerScheduleReconciliationResult reconcileWorkerSchedule({
  required WorkerBookingScheduleModel schedule,
  required int? currentSelectedSessionId,
  required int? preferredSessionId,
  required int? securityCodeSessionId,
  required int? bookingId,
  required int? trackedBookingId,
  required int? trackedSessionId,
}) {
  final selectedWasRemoved =
      currentSelectedSessionId != null &&
      schedule.sessionById(currentSelectedSessionId) == null;
  final securityCodeWasRemoved =
      securityCodeSessionId != null &&
      schedule.sessionById(securityCodeSessionId) == null;
  final trackedSessionWasRemoved =
      trackedBookingId == bookingId &&
      trackedSessionId != null &&
      schedule.sessionById(trackedSessionId) == null;

  return WorkerScheduleReconciliationResult(
    selectedSessionId: _resolveSelectedSessionId(
      schedule,
      currentSelectedSessionId,
      preferredSessionId,
    ),
    clearSecurityCode:
        selectedWasRemoved ||
        securityCodeWasRemoved ||
        schedule.sessions.isEmpty,
    stopLocationTracking: trackedSessionWasRemoved,
  );
}

int? _resolveSelectedSessionId(
  WorkerBookingScheduleModel schedule,
  int? currentSelectedSessionId,
  int? preferredSessionId,
) {
  if (schedule.sessionById(currentSelectedSessionId) != null) {
    return currentSelectedSessionId;
  }
  if (schedule.sessionById(preferredSessionId) != null) {
    return preferredSessionId;
  }

  final nextSessionId = schedule.nextSession?.id;
  if (schedule.sessionById(nextSessionId) != null) {
    return nextSessionId;
  }

  for (final session in schedule.sessions) {
    if (!session.isTerminal && session.id != null) {
      return session.id;
    }
  }

  return schedule.sessions.isEmpty ? null : schedule.sessions.last.id;
}
