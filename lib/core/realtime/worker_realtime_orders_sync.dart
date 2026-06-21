import '../../features/orders/view/manager/bloc/orders_bloc.dart';
import 'cleaning_realtime_contract.dart';

class WorkerRealtimeOrdersSync {
  WorkerRealtimeOrdersSync._();

  static bool shouldProcessWorkerEvent({
    required String eventName,
    required Map<String, dynamic> payload,
  }) {
    if (CleaningRealtimeContract.isLocationEvent(eventName)) return false;

    if (CleaningRealtimeContract.shouldRefreshPendingOrdersForWorkerEvent(
      eventName,
      payload,
    )) {
      return true;
    }

    return CleaningRealtimeContract.extractBookingId(payload) != null;
  }

  /// Returns true when a full list refetch is safer than sync-only updates.
  static bool prefersListRefetch({
    required String eventName,
    required Map<String, dynamic> payload,
  }) {
    final normalized = CleaningRealtimeContract.normalizeEventName(eventName);

    if (normalized == CleaningRealtimeContract.trackingUpdated) {
      return CleaningRealtimeContract.extractBookingId(payload) == null;
    }

    return CleaningRealtimeContract.isLifecycleRefreshEvent(normalized);
  }

  static void dispatchSync({
    required OrdersBloc bloc,
    required String eventName,
    required Map<String, dynamic> payload,
    bool applyToPendingList = false,
  }) {
    if (!shouldProcessWorkerEvent(eventName: eventName, payload: payload)) {
      return;
    }

    bloc.add(
      SyncPendingOrderFromRealtimeEvent(
        eventName: eventName,
        payload: payload,
        applyToPendingList: applyToPendingList,
      ),
    );
  }
}
