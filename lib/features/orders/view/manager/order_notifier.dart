import 'package:flutter/material.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';

abstract class OrderStatusFilter {
  static const activeLifecycle =
      '${CleaningBookingStatus.inProgress},'
      '${CleaningBookingStatus.awaitingStartVerification},'
      '${CleaningBookingStatus.awaitingCustomerCompletion},'
      '${CleaningBookingStatus.timeExtensionRequested}';
}

class OrderNotifier {
  ValueNotifier<String> status = ValueNotifier(
    CleaningBookingStatus.workerAssigned,
  );

  changeStatus(String status) {
    this.status.value = status;
  }
}
