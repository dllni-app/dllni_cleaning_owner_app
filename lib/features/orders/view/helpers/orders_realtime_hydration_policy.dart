import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';

import '../../data/models/cleaning_booking_status.dart';

class OrdersRealtimeHydrationPolicy {
  const OrdersRealtimeHydrationPolicy._();

  static bool shouldRefreshLifecycleList(String eventName) {
    final normalizedEvent = CleaningRealtimeContract.normalizeEventName(eventName);
    return CleaningRealtimeContract.isLifecycleRefreshEvent(normalizedEvent);
  }

  static bool shouldRefreshLifecycleDetails(String eventName) {
    return shouldRefreshLifecycleList(eventName);
  }

  static bool shouldIgnorePendingSync({
    required String eventName,
    required Map<String, dynamic> payload,
  }) {
    final bookingId = CleaningRealtimeContract.extractBookingId(payload);
    final shouldSync =
        CleaningRealtimeContract.shouldRefreshPendingOrdersForWorkerEvent(
      eventName,
      payload,
    );

    return !shouldSync &&
        (bookingId == null ||
            CleaningRealtimeContract.isLocationEvent(eventName));
  }

  static bool shouldRefetchPendingListWhenDetailsMissing({
    required bool applyToPendingList,
  }) {
    return applyToPendingList;
  }

  static bool canUpsertPendingOrder({
    required String? status,
    required bool applyToPendingList,
    required String lastOrdersStatusFilter,
  }) {
    final normalizedStatus = (status ?? '').trim().toLowerCase();
    if (normalizedStatus != CleaningBookingStatus.pending) return false;
    return applyToPendingList ||
        lastOrdersStatusFilter == CleaningBookingStatus.pending;
  }
}
