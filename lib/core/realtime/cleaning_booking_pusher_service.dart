import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:injectable/injectable.dart';

import 'pusher_manager.dart';

typedef CleaningBookingEventHandler =
    void Function(String eventName, Map<String, dynamic> payload);
typedef CleaningBookingChannelErrorHandler =
    void Function(RealtimeChannelError error);

@lazySingleton
class CleaningBookingPusherService {
  CleaningBookingPusherService() : _pusherManager = getIt<PusherManager>();

  final PusherManager _pusherManager;

  final Map<int, CleaningBookingEventHandler> _bookingHandlers =
      <int, CleaningBookingEventHandler>{};
  final Map<int, CleaningBookingEventHandler> _workerHandlers =
      <int, CleaningBookingEventHandler>{};
  final Map<int, CleaningBookingChannelErrorHandler> _bookingErrorHandlers =
      <int, CleaningBookingChannelErrorHandler>{};
  final Map<int, CleaningBookingChannelErrorHandler> _workerErrorHandlers =
      <int, CleaningBookingChannelErrorHandler>{};

  final Map<int, RealtimeListenerHandle> _bookingListenerHandles =
      <int, RealtimeListenerHandle>{};
  final Map<int, RealtimeListenerHandle> _workerListenerHandles =
      <int, RealtimeListenerHandle>{};

  Future<void> ensureInitialized() {
    return _pusherManager.ensureInitialized();
  }

  @Deprecated(
    'Use PusherManager.listen with RealtimeListenerHandle ownership instead.',
  )
  void setBookingHandler(int bookingId, CleaningBookingEventHandler? onEvent) {
    if (onEvent == null) {
      _bookingHandlers.remove(bookingId);
      return;
    }
    _bookingHandlers[bookingId] = onEvent;
  }

  @Deprecated(
    'Use PusherManager.listen with RealtimeListenerHandle ownership instead.',
  )
  void setWorkerHandler(int workerId, CleaningBookingEventHandler? onEvent) {
    if (onEvent == null) {
      _workerHandlers.remove(workerId);
      return;
    }
    _workerHandlers[workerId] = onEvent;
  }

  @Deprecated(
    'Use PusherManager.listen with RealtimeListenerHandle ownership instead.',
  )
  void setBookingErrorHandler(
    int bookingId,
    CleaningBookingChannelErrorHandler? onError,
  ) {
    if (onError == null) {
      _bookingErrorHandlers.remove(bookingId);
      return;
    }
    _bookingErrorHandlers[bookingId] = onError;
  }

  @Deprecated(
    'Use PusherManager.listen with RealtimeListenerHandle ownership instead.',
  )
  void setWorkerErrorHandler(
    int workerId,
    CleaningBookingChannelErrorHandler? onError,
  ) {
    if (onError == null) {
      _workerErrorHandlers.remove(workerId);
      return;
    }
    _workerErrorHandlers[workerId] = onError;
  }

  Future<void> subscribeBookingChannel(int bookingId) async {
    if (_bookingListenerHandles.containsKey(bookingId)) return;
    final handle = await _pusherManager.listen(
      channelName: 'private-cleaning-booking.$bookingId',
      onEvent: (event) {
        final handler = _bookingHandlers[bookingId];
        if (handler == null) return;
        handler(event.eventName, event.payload);
      },
      onChannelError: (error) {
        final handler = _bookingErrorHandlers[bookingId];
        if (handler == null) return;
        handler(error);
      },
    );
    _bookingListenerHandles[bookingId] = handle;
  }

  Future<void> unsubscribeBookingChannel(int bookingId) async {
    final handle = _bookingListenerHandles.remove(bookingId);
    await handle?.dispose();
  }

  Future<void> subscribeWorkerChannel(int workerId) async {
    if (_workerListenerHandles.containsKey(workerId)) return;
    final handle = await _pusherManager.listen(
      channelName: 'private-cleaning-worker.$workerId',
      onEvent: (event) {
        final handler = _workerHandlers[workerId];
        if (handler == null) return;
        handler(event.eventName, event.payload);
      },
      onChannelError: (error) {
        final handler = _workerErrorHandlers[workerId];
        if (handler == null) return;
        handler(error);
      },
    );
    _workerListenerHandles[workerId] = handle;
  }

  Future<void> unsubscribeWorkerChannel(int workerId) async {
    final handle = _workerListenerHandles.remove(workerId);
    await handle?.dispose();
  }

  Future<void> disposeAllForSession() async {
    final bookingHandles = _bookingListenerHandles.values.toList(
      growable: false,
    );
    final workerHandles = _workerListenerHandles.values.toList(growable: false);
    _bookingListenerHandles.clear();
    _workerListenerHandles.clear();
    _bookingHandlers.clear();
    _workerHandlers.clear();
    _bookingErrorHandlers.clear();
    _workerErrorHandlers.clear();

    for (final handle in bookingHandles) {
      await handle.dispose();
    }
    for (final handle in workerHandles) {
      await handle.dispose();
    }
    await _pusherManager.disposeAllForSession();
  }
}
