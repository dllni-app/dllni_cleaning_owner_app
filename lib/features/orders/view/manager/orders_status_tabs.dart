import '../../data/models/cleaning_booking_status.dart';

/// Task-oriented worker views. Backend still accepts its original individual
/// statuses, so old deep links and other API consumers remain compatible.
class OrdersStatusTab {
  const OrdersStatusTab({
    required this.status,
    required this.label,
    required this.workerView,
  });

  final String status;
  final String label;
  final String workerView;

  bool containsStatus(String value) => status.split(',').contains(value);
}

const List<OrdersStatusTab> ordersStatusTabs = <OrdersStatusTab>[
  OrdersStatusTab(
    status: CleaningBookingStatus.pending,
    label: 'جديدة',
    workerView: 'available',
  ),
  OrdersStatusTab(
    status:
        '${CleaningBookingStatus.pending},${CleaningBookingStatus.workerAssigned},'
        '${CleaningBookingStatus.awaitingStartVerification},'
        '${CleaningBookingStatus.awaitingWorkerStartConfirmation}',
    label: 'القادمة',
    workerView: 'mine',
  ),
  OrdersStatusTab(
    status:
        '${CleaningBookingStatus.inProgress},'
        '${CleaningBookingStatus.awaitingCustomerCompletion},'
        '${CleaningBookingStatus.timeExtensionRequested},'
        '${CleaningBookingStatus.underDispute}',
    label: 'قيد التنفيذ',
    workerView: 'mine',
  ),
  OrdersStatusTab(
    status:
        '${CleaningBookingStatus.partiallyCompleted},'
        '${CleaningBookingStatus.completed},${CleaningBookingStatus.cancelled}',
    label: 'السجل',
    workerView: 'mine',
  ),
];
