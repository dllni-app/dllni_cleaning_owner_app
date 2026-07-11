import 'package:flutter/widgets.dart';

class AppForegroundGate {
  AppForegroundGate._();

  static bool _isForeground = true;

  static bool get isForeground => _isForeground;

  static void onResumed() {
    _isForeground = true;
  }

  static void onPaused() {
    _isForeground = false;
  }

  static void onInactive() {
    _isForeground = false;
  }

  static void onHidden() {
    _isForeground = false;
  }

  static void onLifecycleStateChanged(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
  }
}
