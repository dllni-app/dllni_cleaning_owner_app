import 'dart:async';

class OrderDetailsLifecyclePoller {
  OrderDetailsLifecyclePoller({
    required this.shouldPoll,
    required this.onPoll,
    this.interval = const Duration(seconds: 12),
  });

  final bool Function() shouldPoll;
  final void Function() onPoll;
  final Duration interval;
  Timer? _timer;

  void sync() {
    if (!shouldPoll()) {
      stop();
      return;
    }
    if (_timer?.isActive == true) return;
    _timer = Timer.periodic(interval, (_) {
      if (!shouldPoll()) {
        stop();
        return;
      }
      onPoll();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
