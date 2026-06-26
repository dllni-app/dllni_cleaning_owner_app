abstract class CleaningBookingStatus {
  static const pending = 'pending';
  static const workerAssigned = 'worker_assigned';
  static const awaitingStartVerification = 'awaiting_start_verification';
  static const awaitingWorkerStartConfirmation =
      'awaiting_worker_start_confirmation';
  static const inProgress = 'in_progress';
  static const awaitingCustomerCompletion = 'awaiting_customer_completion';
  static const timeExtensionRequested = 'time_extension_requested';
  static const underDispute = 'under_dispute';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static String toArabic(String status) {
    switch (status) {
      case pending:
        return 'قيد الانتظار';

      case workerAssigned:
        return 'تم تعيين العامل';

      case awaitingStartVerification:
        return 'بانتظار التحقق من بدء الخدمة';

      case awaitingWorkerStartConfirmation:
        return 'بانتظار تأكيد العامل لبدء الخدمة';

      case inProgress:
        return 'قيد التنفيذ';

      case awaitingCustomerCompletion:
        return 'بانتظار تأكيد العميل لإتمام الخدمة';

      case timeExtensionRequested:
        return 'تم طلب تمديد الوقت';

      case underDispute:
        return 'قيد المراجعة';

      case completed:
        return 'مكتمل';

      case cancelled:
        return 'ملغي';

      default:
        return status;
    }
  }
}
