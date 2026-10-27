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
  static const partiallyCompleted = 'partially_completed';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static String toArabic(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    switch (normalized) {
      case pending:
        return 'قيد الانتظار';
      case 'accepted':
        return 'تم القبول';
      case 'accepted_waiting_team':
        return 'تم القبول - بانتظار اكتمال الفريق';
      case 'accepted_waiting_for_order_start':
        return 'تم القبول - بانتظار بدء الطلب';
      case 'start_approved':
        return 'تم تأكيد بدء العمل';
      case 'scheduled':
        return 'مجدول';
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
      case partiallyCompleted:
        return 'مكتمل جزئياً';
      case completed:
        return 'مكتمل';
      case cancelled:
        return 'ملغي';
      default:
        // Unknown English backend enums must never leak into Arabic UI.
        return RegExp(r'[\u0600-\u06FF]').hasMatch(status)
            ? status
            : 'قيد المتابعة';
    }
  }
}
