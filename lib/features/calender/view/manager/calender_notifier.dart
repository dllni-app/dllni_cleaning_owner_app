import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CalenderNotifier {
  ValueNotifier<String> selectedDate = ValueNotifier<String>(DateFormat('d MMMM y', 'ar').format(DateTime.now()));

  changeSelectedDate(DateTime value) {
    selectedDate.value = DateFormat('d MMMM y', 'ar').format(value);
  }
}
