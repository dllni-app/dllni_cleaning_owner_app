import 'package:flutter/material.dart';

class ProfileNotifier {
  ValueNotifier<String> status = ValueNotifier<String>('open');

  changeStatus(val) {
    status.value = val;
  }
}
