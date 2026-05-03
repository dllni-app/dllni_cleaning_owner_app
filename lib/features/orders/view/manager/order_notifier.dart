import 'package:flutter/material.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';

class OrderNotifier {
  ValueNotifier<String> status = ValueNotifier(
    CleaningBookingStatus.workerAssigned,
  );

  changeStatus(String status) {
    this.status.value = status;
  }
}
