import 'package:flutter/material.dart';

import 'orders_status_tabs.dart';

class OrderNotifier {
  OrderNotifier() : status = ValueNotifier(ordersStatusTabs.first.status);

  ValueNotifier<String> status;

  void changeStatus(String value) {
    status.value = value;
  }
}
