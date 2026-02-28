import 'package:flutter/material.dart';

class MainNotifier {
  ValueNotifier<int> pageIndex = ValueNotifier<int>(0);

  changePageIndex(i) {
    pageIndex.value = i;
  }
}
