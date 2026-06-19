import '../../data/models/cleaning_booking_status.dart';
import '../../data/models/fetch_orders_usecase_model.dart';

enum CleaningWorkerOrderStatus {
  pending,
  acceptedWaitingTeam,
  acceptedWaitingForOrderStart,
  workerAssigned,
  awaitingStartVerification,
  awaitingWorkerStartConfirmation,
  inProgress,
  awaitingCustomerCompletion,
  timeExtensionRequested,
  completed,
  cancelled,
  unknown,
}

CleaningWorkerOrderStatus parseCleaningWorkerOrderStatus(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case CleaningBookingStatus.pending:
      return CleaningWorkerOrderStatus.pending;
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
    case CleaningBookingStatus.inProgress:
      return CleaningWorkerOrderStatus.inProgress;
    case CleaningBookingStatus.awaitingCustomerCompletion:
      return CleaningWorkerOrderStatus.awaitingCustomerCompletion;
    case CleaningBookingStatus.timeExtensionRequested:
      return CleaningWorkerOrderStatus.timeExtensionRequested;
    case CleaningBookingStatus.completed:
      return CleaningWorkerOrderStatus.completed;
    case CleaningBookingStatus.cancelled:
      return CleaningWorkerOrderStatus.cancelled;
    default:
      return CleaningWorkerOrderStatus.unknown;
  }
}

String localArabicWorkerStatusLabel(CleaningWorkerOrderStatus status) {
  switch (status) {
    case CleaningWorkerOrderStatus.pending:
      return 'بانتظار القبول';
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
    case CleaningWorkerOrderStatus.inProgress:
      return 'قيد التنفيذ';
    case CleaningWorkerOrderStatus.awaitingCustomerCompletion:
      return 'بانتظار تأكيد العميل للإنهاء';
    case CleaningWorkerOrderStatus.timeExtensionRequested:
      return 'طلب تمديد وقت';
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
    if (assignment == null) return false;
    final status = assignment.status?.trim().toLowerCase();
    return status == 'accepted' || (assignment.acceptedAt?.isNotEmpty ?? false);
  }

  CleaningWorkerOrderStatus get effectiveWorkerStatus {
    final fromWorkerField = parseCleaningWorkerOrderStatus(workerOrderStatus);
    if (fromWorkerField != CleaningWorkerOrderStatus.unknown) {
      return fromWorkerField;
    }

    final fromStatus = parseCleaningWorkerOrderStatus(status);
    if (fromStatus != CleaningWorkerOrderStatus.pending) {
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

  String get effectiveWorkerStatusLabel {
    final label = workerOrderStatusLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return localArabicWorkerStatusLabel(effectiveWorkerStatus);
  }
}
