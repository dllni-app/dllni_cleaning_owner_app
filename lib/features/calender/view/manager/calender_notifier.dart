import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:flutter/material.dart';

class CalenderNotifier {
  ValueNotifier<String> selectedDate = ValueNotifier<String>(
    CleaningArabicTimeFormatter.formatCalendarSelectedDate(DateTime.now()),
  );

  changeSelectedDate(DateTime value) {
    selectedDate.value =
        CleaningArabicTimeFormatter.formatCalendarSelectedDate(value);
  }
}
