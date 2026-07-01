import 'package:common_package/common_package.dart';

import '../../data/models/cleaning_booking_status.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import 'order_lifecycle_policy.dart';
import 'orders_lifecycle_failure_message_mapper.dart';
import 'orders_pending_order_list_hydrator.dart';

class OrdersAcceptFlowPolicy {
  const OrdersAcceptFlowPolicy._();

  static String? resolvedStatus({
    required FetchOrdersUsecaseModelDataItem? updatedOrder,
    String? fallbackStatus,
  }) {
    return (updatedOrder?.status ?? fallbackStatus)?.trim().toLowerCase();
  }

  static bool shouldKeepAcceptedOrderInPendingList({
    required FetchOrdersUsecaseModelDataItem? updatedOrder,
    String? fallbackStatus,
  }) {
    return updatedOrder != null &&
        resolvedStatus(
              updatedOrder: updatedOrder,
              fallbackStatus: fallbackStatus,
            ) ==
            CleaningBookingStatus.pending;
  }

  static bool shouldRefreshWorkerAssignedList({
    required FetchOrdersUsecaseModelDataItem? updatedOrder,
    String? fallbackStatus,
  }) {
    return resolvedStatus(
          updatedOrder: updatedOrder,
          fallbackStatus: fallbackStatus,
        ) ==
        CleaningBookingStatus.workerAssigned;
  }

  static PaginationStateModel<FetchOrdersUsecaseModelDataItem>
      applyAcceptSuccessToPendingList({
    required PaginationStateModel<FetchOrdersUsecaseModelDataItem> current,
    required int bookingId,
    required FetchOrdersUsecaseModelDataItem? updatedOrder,
    String? fallbackStatus,
  }) {
    if (shouldKeepAcceptedOrderInPendingList(
      updatedOrder: updatedOrder,
      fallbackStatus: fallbackStatus,
    )) {
      return OrdersPendingOrderListHydrator.upsert(current, updatedOrder!);
    }

    return current.removeWhere((order) => order.id == bookingId);
  }

  static String mapAcceptFailureMessage(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('already accepted') ||
        raw.contains('accepted by a worker') ||
        raw.contains('already been accepted') ||
        raw.contains('no longer available') ||
        raw.contains('not available')) {
      return OrderLifecyclePolicy.orderNoLongerAvailableMessage;
    }

    return OrdersLifecycleFailureMessageMapper.map(
      failure,
      invalidStateMessage: OrderLifecyclePolicy.orderNoLongerAvailableMessage,
    );
  }
}
