import 'package:flutter/material.dart';

class OrderNotifier {
  ValueNotifier<String> status = ValueNotifier('worker_assigned');

  changeStatus(String status) {
    this.status.value = status;
  }
}
