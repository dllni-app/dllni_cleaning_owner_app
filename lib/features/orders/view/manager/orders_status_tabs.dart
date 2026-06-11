import '../../data/models/cleaning_booking_status.dart';

class OrdersStatusTab {
  const OrdersStatusTab({required this.status, required this.label});

  final String status;
  final String label;
}

const List<OrdersStatusTab> ordersStatusTabs = <OrdersStatusTab>[
  /*OrdersStatusTab(
    status: CleaningBookingStatus.pending,
    label: 'جديدة',
  ),*/
  OrdersStatusTab(status: CleaningBookingStatus.workerAssigned, label: 'مؤكدة'),
  OrdersStatusTab(
    status: CleaningBookingStatus.awaitingStartVerification,
    label: 'بانتظار التحقق',
  ),
  OrdersStatusTab(
    status: CleaningBookingStatus.awaitingWorkerStartConfirmation,
    label: 'جاهز للبدء',
  ),
  OrdersStatusTab(
    status: CleaningBookingStatus.inProgress,
    label: 'قيد التنفيذ',
  ),
  OrdersStatusTab(
    status: CleaningBookingStatus.awaitingCustomerCompletion,
    label: 'تأكيد الإكمال',
  ),
  OrdersStatusTab(
    status: CleaningBookingStatus.timeExtensionRequested,
    label: 'تمديد الوقت',
  ),
  OrdersStatusTab(status: CleaningBookingStatus.completed, label: 'مكتملة'),
  OrdersStatusTab(status: CleaningBookingStatus.cancelled, label: 'ملغية'),
];
