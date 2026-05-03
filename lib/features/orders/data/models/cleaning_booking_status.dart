abstract class CleaningBookingStatus {
  static const pending = 'pending';
  static const workerAssigned = 'worker_assigned';
  static const awaitingStartVerification = 'awaiting_start_verification';
  static const inProgress = 'in_progress';
  static const awaitingCustomerCompletion = 'awaiting_customer_completion';
  static const timeExtensionRequested = 'time_extension_requested';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}
