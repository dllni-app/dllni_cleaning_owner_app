import '../../data/models/cleaning_booking_status.dart';
import '../../data/models/fetch_orders_usecase_model.dart';

enum CleaningWorkerOrderStatus {
  pending,
  accepted,
  acceptedWaitingTeam,
  acceptedWaitingForOrderStart,
  workerAssigned,
  awaitingStartVerification,
  awaitingWorkerStartConfirmation,
  startApproved,
  rejected,
  withdrawn,
  inProgress,
  awaitingCustomerCompletion,
  timeExtensionRequested,
  underDispute,
  completed,
  cancelled,
  unknown,
}

CleaningWorkerOrderStatus parseCleaningWorkerOrderStatus(String? value) {
  // The API may use snake_case values or human-readable English labels.
  // Both must resolve to one Arabic label instead of leaking raw status text.
  final normalized = (value ?? '')
      .trim()
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_');
  switch (normalized) {
    case CleaningBookingStatus.pending:
      return CleaningWorkerOrderStatus.pending;
    case 'accepted':
      return CleaningWorkerOrderStatus.accepted;
    case 'accepted_waiting_team':
      return CleaningWorkerOrderStatus.acceptedWaitingTeam;
    case 'accepted_waiting_for_order_start':
      return CleaningWorkerOrderStatus.acceptedWaitingForOrderStart;
    case CleaningBookingStatus.workerAssigned:
      return CleaningWorkerOrderStatus.workerAssigned;
    case CleaningBookingStatus.awaitingStartVerification:
      return CleaningWorkerOrderStatus.awaitingStartVerification;
    case CleaningBookingStatus.awaitingWorkerStartConfirmation:
      return CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation;
    case 'start_approved':
      return CleaningWorkerOrderStatus.startApproved;
    case 'rejected':
      return CleaningWorkerOrderStatus.rejected;
    case 'withdrawn':
      return CleaningWorkerOrderStatus.withdrawn;
    case CleaningBookingStatus.inProgress:
      return CleaningWorkerOrderStatus.inProgress;
    case CleaningBookingStatus.awaitingCustomerCompletion:
      return CleaningWorkerOrderStatus.awaitingCustomerCompletion;
    case CleaningBookingStatus.timeExtensionRequested:
      return CleaningWorkerOrderStatus.timeExtensionRequested;
    case CleaningBookingStatus.underDispute:
      return CleaningWorkerOrderStatus.underDispute;
    case CleaningBookingStatus.completed:
      return CleaningWorkerOrderStatus.completed;
    case CleaningBookingStatus.cancelled:
      return CleaningWorkerOrderStatus.cancelled;
    default:
      return CleaningWorkerOrderStatus.unknown;
  }
}

/// Converts a status received from the API to a display-safe Arabic label.
/// Do not expose unrecognized English status values in an Arabic screen.
String arabicCleaningStatusLabel(
  String? raw, {
  String fallback = 'قيد المتابعة',
}) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return fallback;
  final parsed = parseCleaningWorkerOrderStatus(value);
  if (parsed != CleaningWorkerOrderStatus.unknown) {
    return localArabicWorkerStatusLabel(parsed);
  }
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  switch (normalized) {
    case 'scheduled':
      return 'مجدول';
    case 'partially_completed':
      return 'مكتمل جزئياً';
    case 'active':
      return 'نشط';
    case 'available':
    case 'open':
      return 'متاح';
    case 'waiting_customer':
      return 'بانتظار العميل';
    case 'needs_response':
      return 'بانتظار الرد';
    case 'rework':
      return 'إعادة تنفيذ العمل';
    case 'disputed':
      return 'قيد المراجعة';
    case 'travelling':
    case 'traveling':
    case 'on_the_way':
    case 'en_route':
      return 'في الطريق إلى العميل';
    case 'not_assigned':
      return 'لم يتم التعيين';
    case 'assigned':
      return 'تم التعيين';
    case 'skipped':
      return 'تم التجاوز';
  }
  // Localized labels supplied by the backend are safe to retain.
  if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) return value;
  return fallback;
}

bool isWorkerAcceptedAssignmentStatusValue(String? value) {
  switch (parseCleaningWorkerOrderStatus(value)) {
    case CleaningWorkerOrderStatus.accepted:
    case CleaningWorkerOrderStatus.acceptedWaitingTeam:
    case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
    case CleaningWorkerOrderStatus.awaitingStartVerification:
    case CleaningWorkerOrderStatus.startApproved:
      return true;
    default:
      return false;
  }
}

bool isWorkerRejectedOrClosedAssignmentStatusValue(String? value) {
  switch (parseCleaningWorkerOrderStatus(value)) {
    case CleaningWorkerOrderStatus.rejected:
    case CleaningWorkerOrderStatus.withdrawn:
    case CleaningWorkerOrderStatus.cancelled:
      return true;
    default:
      return false;
  }
}

bool isGlobalTerminalWorkerStatus(CleaningWorkerOrderStatus status) {
  switch (status) {
    case CleaningWorkerOrderStatus.completed:
    case CleaningWorkerOrderStatus.cancelled:
    case CleaningWorkerOrderStatus.underDispute:
      return true;
    default:
      return false;
  }
}

bool isGlobalActiveWorkerStatus(CleaningWorkerOrderStatus status) {
  switch (status) {
    case CleaningWorkerOrderStatus.inProgress:
    case CleaningWorkerOrderStatus.awaitingCustomerCompletion:
    case CleaningWorkerOrderStatus.timeExtensionRequested:
      return true;
    default:
      return false;
  }
}

String localArabicWorkerStatusLabel(CleaningWorkerOrderStatus status) {
  switch (status) {
    case CleaningWorkerOrderStatus.pending:
      return 'بانتظار القبول';
    case CleaningWorkerOrderStatus.accepted:
      return 'تم القبول';
    case CleaningWorkerOrderStatus.acceptedWaitingTeam:
      return 'تم القبول - بانتظار اكتمال الفريق';
    case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
      return 'تم القبول - بانتظار بدء الطلب';
    case CleaningWorkerOrderStatus.workerAssigned:
      return 'تم تعيين العامل';
    case CleaningWorkerOrderStatus.awaitingStartVerification:
      return 'بانتظار تأكيد رمز الوصول';
    case CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation:
      return 'بانتظار بدء العمل من العامل';
    case CleaningWorkerOrderStatus.startApproved:
      return 'تم تأكيد بدء العمل - بانتظار باقي العمال';
    case CleaningWorkerOrderStatus.rejected:
      return 'تم رفض الطلب';
    case CleaningWorkerOrderStatus.withdrawn:
      return 'تم الانسحاب من الطلب';
    case CleaningWorkerOrderStatus.inProgress:
      return 'قيد التنفيذ';
    case CleaningWorkerOrderStatus.awaitingCustomerCompletion:
      return 'بانتظار تأكيد العميل للإنهاء';
    case CleaningWorkerOrderStatus.timeExtensionRequested:
      return 'طلب تمديد وقت';
    case CleaningWorkerOrderStatus.underDispute:
      return 'قيد المراجعة';
    case CleaningWorkerOrderStatus.completed:
      return 'مكتمل';
    case CleaningWorkerOrderStatus.cancelled:
      return 'ملغي';
    case CleaningWorkerOrderStatus.unknown:
      return 'حالة غير معروفة';
  }
}

extension FetchOrdersWorkerStatusX on FetchOrdersUsecaseModelDataItem {
  int? get cleaningBookingId => id;

  bool get _hasCurrentWorkerAccepted {
    final assignment = myAssignment;
    return isWorkerAcceptedAssignmentStatusValue(workerOrderStatus) ||
        isWorkerAcceptedAssignmentStatusValue(assignment?.status) ||
        (assignment?.acceptedAt?.isNotEmpty ?? false);
  }

  CleaningWorkerOrderStatus get effectiveWorkerStatus {
    final fromStatus = parseCleaningWorkerOrderStatus(status);
    final fromWorkerField = parseCleaningWorkerOrderStatus(workerOrderStatus);
    if (fromWorkerField != CleaningWorkerOrderStatus.unknown) {
      // A worker may have declined or withdrawn while other team members keep
      // the parent booking in progress/completed. Never paint that person as
      // executing or paid simply because of the global booking status.
      if (fromWorkerField == CleaningWorkerOrderStatus.rejected ||
          fromWorkerField == CleaningWorkerOrderStatus.withdrawn ||
          fromWorkerField == CleaningWorkerOrderStatus.cancelled ||
          fromWorkerField == CleaningWorkerOrderStatus.completed) {
        return fromWorkerField;
      }
      // A stale pending/accepted snapshot cannot reopen a globally finished
      // booking. A real per-worker terminal status above still takes priority.
      if (isGlobalTerminalWorkerStatus(fromStatus)) return fromStatus;
      if (fromWorkerField == CleaningWorkerOrderStatus.pending &&
          isGlobalActiveWorkerStatus(fromStatus)) {
        return fromStatus;
      }
      return _normalizePendingAcceptedStatus(fromWorkerField);
    }

    final fromAssignment = parseCleaningWorkerOrderStatus(myAssignment?.status);
    if (fromAssignment != CleaningWorkerOrderStatus.unknown) {
      if (fromAssignment == CleaningWorkerOrderStatus.rejected ||
          fromAssignment == CleaningWorkerOrderStatus.withdrawn ||
          fromAssignment == CleaningWorkerOrderStatus.cancelled ||
          fromAssignment == CleaningWorkerOrderStatus.completed) {
        return fromAssignment;
      }
      if (isGlobalTerminalWorkerStatus(fromStatus)) return fromStatus;
      return _normalizePendingAcceptedStatus(fromAssignment);
    }

    if (fromStatus != CleaningWorkerOrderStatus.pending &&
        fromStatus != CleaningWorkerOrderStatus.unknown) {
      return fromStatus;
    }

    if (!_hasCurrentWorkerAccepted) {
      return CleaningWorkerOrderStatus.pending;
    }

    if (isSearchingForWorkers) {
      return CleaningWorkerOrderStatus.acceptedWaitingTeam;
    }

    return CleaningWorkerOrderStatus.acceptedWaitingForOrderStart;
  }

  CleaningWorkerOrderStatus _normalizePendingAcceptedStatus(
    CleaningWorkerOrderStatus workerStatus,
  ) {
    final normalizedGlobal = (status ?? '').trim().toLowerCase();
    if (normalizedGlobal != CleaningBookingStatus.pending) return workerStatus;

    if (workerStatus == CleaningWorkerOrderStatus.accepted ||
        workerStatus ==
            CleaningWorkerOrderStatus.acceptedWaitingForOrderStart) {
      return workerAcceptance?.isFulfilled == true
          ? CleaningWorkerOrderStatus.acceptedWaitingForOrderStart
          : CleaningWorkerOrderStatus.acceptedWaitingTeam;
    }

    return workerStatus;
  }

  String get effectiveWorkerStatusLabel {
    // The booking may retain a stale team-waiting label after V2 visit seats
    // have been filled. Prefer the live accepted seat count for display only.
    final accepted = acceptedWorkersCount ?? workerAcceptance?.accepted ?? 0;
    final required =
        requiredWorkersCount ??
        workerAcceptance?.required ??
        numberOfWorkers ??
        1;
    if (required > 1 &&
        accepted >= required &&
        (effectiveWorkerStatus ==
                CleaningWorkerOrderStatus.acceptedWaitingTeam ||
            effectiveWorkerStatus ==
                CleaningWorkerOrderStatus.acceptedWaitingForOrderStart)) {
      return 'تم القبول - بانتظار بدء الطلب';
    }
    final label = workerOrderStatusLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return arabicCleaningStatusLabel(
        label,
        fallback: localArabicWorkerStatusLabel(effectiveWorkerStatus),
      );
    }
    return localArabicWorkerStatusLabel(effectiveWorkerStatus);
  }
}
