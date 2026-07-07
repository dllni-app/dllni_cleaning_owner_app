import 'package:flutter/material.dart';

import '../../data/models/cleaning_booking_status.dart';

class OrderNotifier {
  OrderNotifier()
      : status = ValueNotifier(CleaningBookingStatus.workerAssigned);

  ValueNotifier<String> status;

  void changeStatus(String value) {
    status.value = value;
  }
}
