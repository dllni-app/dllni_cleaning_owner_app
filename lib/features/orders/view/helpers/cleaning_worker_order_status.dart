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
  switch ((value ?? '').trim().toLowerCase()) {
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
    if (isGlobalTerminalWorkerStatus(fromStatus) ||
        isGlobalActiveWorkerStatus(fromStatus)) {
      return fromStatus;
    }

    final fromWorkerField = parseCleaningWorkerOrderStatus(workerOrderStatus);
    if (fromWorkerField != CleaningWorkerOrderStatus.unknown) {
      return _normalizePendingAcceptedStatus(fromWorkerField);
    }

    final fromAssignment = parseCleaningWorkerOrderStatus(myAssignment?.status);
    if (fromAssignment != CleaningWorkerOrderStatus.unknown) {
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
        workerStatus == CleaningWorkerOrderStatus.acceptedWaitingForOrderStart) {
      return CleaningWorkerOrderStatus.acceptedWaitingTeam;
    }

    return workerStatus;
  }

  String get effectiveWorkerStatusLabel {
    final label = workerOrderStatusLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return localArabicWorkerStatusLabel(effectiveWorkerStatus);
  }
}
