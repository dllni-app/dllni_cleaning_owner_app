import 'package:flutter/foundation.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class MainTabNavigation {
  MainTabNavigation._();

  static final MainTabNavigation instance = MainTabNavigation._();
  static const int tabCount = 4;

  final ValueNotifier<int> _ordersStatusRequestId = ValueNotifier<int>(0);

  PersistentTabController? _controller;
  int _initialIndex = 0;
  String? _pendingOrdersInitialStatus;

  ValueListenable<int> get ordersStatusRequestIdListenable =>
      _ordersStatusRequestId;

  int get initialIndex => _initialIndex;

  int get currentIndex => _controller?.index ?? _initialIndex;

  void configureInitialState({
    required int index,
    String? ordersInitialStatus,
  }) {
    _initialIndex = _sanitizeIndex(index);
    _setPendingOrdersStatus(ordersInitialStatus, notify: false);
  }

  PersistentTabController createController() {
    return PersistentTabController(initialIndex: _initialIndex);
  }

  void attachController(PersistentTabController controller) {
    _controller = controller;
    if (controller.index != _initialIndex) {
      controller.jumpToTab(_initialIndex);
    }
  }

  void detachController(PersistentTabController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
    }
  }

  bool jumpToTab(int index, {String? ordersInitialStatus}) {
    _initialIndex = _sanitizeIndex(index);
    _setPendingOrdersStatus(ordersInitialStatus, notify: true);
    final controller = _controller;
    if (controller == null) return false;
    controller.jumpToTab(_initialIndex);
    return true;
  }

  String? consumePendingOrdersInitialStatus() {
    final status = _pendingOrdersInitialStatus;
    _pendingOrdersInitialStatus = null;
    return status;
  }

  int _sanitizeIndex(int index) {
    return index.clamp(0, tabCount - 1).toInt();
  }

  void _setPendingOrdersStatus(String? status, {required bool notify}) {
    final normalized = status?.trim();
    if (normalized == null || normalized.isEmpty) return;
    _pendingOrdersInitialStatus = normalized;
    if (notify) {
      _ordersStatusRequestId.value++;
    }
  }
}
