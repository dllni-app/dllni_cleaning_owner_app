import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:injectable/injectable.dart';

import 'pusher_manager.dart';

typedef CleaningBookingEventHandler =
    void Function(String eventName, Map<String, dynamic> payload);
typedef CleaningBookingChannelErrorHandler =
    void Function(RealtimeChannelError error);

class _WorkerChannelSubscription {
  _WorkerChannelSubscription(this.handle);

  final RealtimeListenerHandle handle;
  final List<CleaningBookingEventHandler> eventHandlers =
      <CleaningBookingEventHandler>[];
  final List<CleaningBookingChannelErrorHandler> errorHandlers =
      <CleaningBookingChannelErrorHandler>[];
}

@lazySingleton
class CleaningBookingPusherService {
  CleaningBookingPusherService() : _pusherManager = getIt<PusherManager>();

  final PusherManager _pusherManager;

  final Map<int, RealtimeListenerHandle> _bookingListenerHandles =
      <int, RealtimeListenerHandle>{};
  final Map<int, _WorkerChannelSubscription> _workerSubscriptions =
      <int, _WorkerChannelSubscription>{};

  Future<void> ensureInitialized() => _pusherManager.ensureInitialized();

  Future<void> subscribeBookingChannel({
    required int bookingId,
    required CleaningBookingEventHandler onEvent,
    CleaningBookingChannelErrorHandler? onError,
  }) async {
    if (_bookingListenerHandles.containsKey(bookingId)) return;

    final handle = await _pusherManager.listen(
      channelName: 'private-cleaning-booking.$bookingId',
      onEvent: (event) => onEvent(event.eventName, event.payload),
      onChannelError: onError,
    );
    _bookingListenerHandles[bookingId] = handle;
  }

  Future<RealtimeListenerHandle> subscribeWorkerChannel({
    required int workerId,
    required CleaningBookingEventHandler onEvent,
    CleaningBookingChannelErrorHandler? onError,
  })
  async {
    final existing = _workerSubscriptions[workerId];
    if (existing != null) {
      existing.eventHandlers.add(onEvent);
      if (onError != null) {
        existing.errorHandlers.add(onError);
      }
      return RealtimeListenerHandle(
        () => _removeWorkerSubscriber(
          workerId: workerId,
          onEvent: onEvent,
          onError: onError,
        ),
      );
    }

    late final _WorkerChannelSubscription subscription;
    final handle = await _pusherManager.listen(
      channelName: 'private-cleaning-worker.$workerId',
      onEvent: (event) {
        final handlers = _workerSubscriptions[workerId]?.eventHandlers;
        if (handlers == null || handlers.isEmpty) return;
        for (final callback in List<CleaningBookingEventHandler>.of(handlers)) {
          callback(event.eventName, event.payload);
        }
      },
      onChannelError: (error) {
        final handlers = _workerSubscriptions[workerId]?.errorHandlers;
        if (handlers == null || handlers.isEmpty) return;
        for (final callback
            in List<CleaningBookingChannelErrorHandler>.of(handlers)) {
          callback(error);
        }
      },
    );

    subscription = _WorkerChannelSubscription(handle)
      ..eventHandlers.add(onEvent);
    if (onError != null) {
      subscription.errorHandlers.add(onError);
    }
    _workerSubscriptions[workerId] = subscription;

    return RealtimeListenerHandle(
      () => _removeWorkerSubscriber(
        workerId: workerId,
        onEvent: onEvent,
        onError: onError,
      ),
    );
  }

  Future<void> _removeWorkerSubscriber({
    required int workerId,
    required CleaningBookingEventHandler onEvent,
    CleaningBookingChannelErrorHandler? onError,
  })
  async {
    final subscription = _workerSubscriptions[workerId];
    if (subscription == null) return;

    subscription.eventHandlers.remove(onEvent);
    if (onError != null) {
      subscription.errorHandlers.remove(onError);
    }

    if (subscription.eventHandlers.isNotEmpty) return;

    _workerSubscriptions.remove(workerId);
    await subscription.handle.dispose();
  }

  Future<void> disposeAllForSession() async {
    final bookingHandles =
        _bookingListenerHandles.values.toList(growable: false);
    _bookingListenerHandles.clear();

    final workerSubscriptions =
        _workerSubscriptions.values.toList(growable: false);
    _workerSubscriptions.clear();

    for (final handle in bookingHandles) {
      await handle.dispose();
    }
    for (final subscription in workerSubscriptions) {
      await subscription.handle.dispose();
    }

    await _pusherManager.disposeAllForSession();
  }
}
