import 'dart:async';

typedef CleaningRealtimeRefreshCallback = FutureOr<void> Function(int bookingId);

class CleaningRealtimeRefreshQueue {
  CleaningRealtimeRefreshQueue({
    required this.onRefresh,
    this.debounce = const Duration(milliseconds: 150),
  });

  final CleaningRealtimeRefreshCallback onRefresh;
  final Duration debounce;
  final Map<int, Timer> _timers = <int, Timer>{};
  final Set<int> _inFlight = <int>{};
  final Set<int> _queuedAgain = <int>{};

  void enqueue(int bookingId) {
    _timers.remove(bookingId)?.cancel();
    _timers[bookingId] = Timer(debounce, () => _flush(bookingId));
  }

  Future<void> _flush(int bookingId) async {
    _timers.remove(bookingId)?.cancel();
    if (_inFlight.contains(bookingId)) {
      _queuedAgain.add(bookingId);
      return;
    }

    _inFlight.add(bookingId);
    try {
      await onRefresh(bookingId);
    } finally {
      _inFlight.remove(bookingId);
      if (_queuedAgain.remove(bookingId)) {
        enqueue(bookingId);
      }
    }
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _inFlight.clear();
    _queuedAgain.clear();
  }
}
