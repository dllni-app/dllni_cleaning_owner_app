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
    final raw = failure.message.trim();
    final normalized = raw.toLowerCase();

    if (normalized.contains('overlaps another confirmed booking') ||
        (normalized.contains('schedule') && normalized.contains('overlap'))) {
      return 'لا يمكن قبول الطلب لأن موعده يتعارض مع حجز مؤكد آخر في جدولك.';
    }

    if (normalized.contains('commission') ||
        normalized.contains('deposit') ||
        normalized.contains('allowance') ||
        normalized.contains('solvency') ||
        normalized.contains('not eligible')) {
      return 'لا يمكن قبول الطلب حالياً لأن رصيد التأمين أو حد السماح لا يغطي شروط قبول هذا الطلب.';
    }

    if (normalized.contains('worker home location is required')) {
      return 'يرجى استكمال عنوان وموقع منزل العامل قبل قبول الطلبات.';
    }

    if (normalized.contains('customer location coordinates are required')) {
      return 'لا يمكن قبول الطلب لأن عنوان العميل لا يحتوي على موقع صحيح على الخريطة.';
    }

    if (normalized.contains('gender preference does not match')) {
      return 'لا يمكن قبول الطلب لأن تفضيل جنس العامل في الطلب لا يطابق بيانات حسابك.';
    }

    if (normalized.contains('reserved for a different preferred worker')) {
      return 'هذا الطلب محجوز لعامل مفضل آخر.';
    }

    if (normalized.contains('already accepted') ||
        normalized.contains('accepted by a worker') ||
        normalized.contains('already been accepted') ||
        normalized.contains('required number of workers') ||
        normalized.contains('cannot be accepted in current status') ||
        normalized.contains('no longer available') ||
        normalized.contains('not available')) {
      return OrderLifecyclePolicy.orderNoLongerAvailableMessage;
    }

    if (failure.statusCode == 422) {
      if (!_looksLikeGenericTransportError(normalized) && raw.isNotEmpty) {
        return ErrorMessageFormatter.format(raw);
      }
      return 'تعذر قبول الطلب بسبب أحد شروط القبول. حدّث الطلب وتحقق من الموعد وبيانات الحساب ثم حاول مجدداً.';
    }

    return OrdersLifecycleFailureMessageMapper.map(
      failure,
      invalidStateMessage: OrderLifecyclePolicy.orderNoLongerAvailableMessage,
    );
  }

  static bool _looksLikeGenericTransportError(String message) {
    return message.contains('status code of 422') ||
        message.contains('requestoptions.validatestatus') ||
        message.contains('dioexception');
  }
}
