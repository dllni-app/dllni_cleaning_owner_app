import '../../data/models/cleaning_booking_status.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../manager/bloc/orders_bloc.dart';
import 'package:common_package/common_package.dart';

/// Single source of truth for order action visibility (card + details screens).
class OrderLifecyclePolicy {
  OrderLifecyclePolicy._();

  static bool isPending(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.pending;

  static bool isTimeExtensionRequested(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.timeExtensionRequested;

  static bool isCustomerDataHidden(FetchOrdersUsecaseModelDataItem order) =>
      isPending(order);

  static bool hasCurrentWorkerAccepted(FetchOrdersUsecaseModelDataItem order) {
    final assignment = order.myAssignment;
    if (assignment == null) return false;
    final status = assignment.status?.trim().toLowerCase();
    return status == 'accepted' || (assignment.acceptedAt?.isNotEmpty ?? false);
  }

  static bool isAcceptedWaiting(FetchOrdersUsecaseModelDataItem order) =>
      isPending(order) && hasCurrentWorkerAccepted(order);

  static bool canAcceptReject(FetchOrdersUsecaseModelDataItem order) =>
      isPending(order) && !hasCurrentWorkerAccepted(order);

  static bool canStartTravel(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.workerAssigned &&
      order.startedTravelAt == null;

  static bool canCancel(FetchOrdersUsecaseModelDataItem order) =>
      canStartTravel(order) &&
      order.id != null &&
      (order.bookingNumber?.trim().isNotEmpty ?? false);

  static bool showFollowOnly(FetchOrdersUsecaseModelDataItem order) =>
      !canAcceptReject(order) && !canStartTravel(order);

  static String acceptedWaitingLabel(FetchOrdersUsecaseModelDataItem order) {
    if (order.isSearchingForWorkers) {
      return 'تم قبولك - بانتظار اكتمال الفريق';
    }
    return 'تم قبولك - بانتظار بدء الطلب';
  }

  static String acceptedWaitingMessage(FetchOrdersUsecaseModelDataItem order) {
    final acceptance = order.workerAcceptance;
    final accepted = acceptance?.accepted;
    final required = acceptance?.required ?? order.numberOfWorkers;
    if (order.isSearchingForWorkers && required != null && required > 0) {
      return 'تم قبولك في هذا الطلب. تم قبول ${accepted ?? 0} من $required عمال، وسيبدأ الطلب بعد اكتمال العدد المطلوب.';
    }
    if (order.isSearchingForWorkers) {
      return 'تم قبولك في هذا الطلب. ننتظر اكتمال عدد العمال المطلوب لبدء الطلب.';
    }
    return 'تم قبولك في هذا الطلب. بانتظار العميل أو النظام للانتقال إلى مرحلة بدء الخدمة.';
  }

  static bool canArrive(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.workerAssigned &&
      order.startedTravelAt != null &&
      order.id != null;

  static bool isAwaitingStartVerification(
    FetchOrdersUsecaseModelDataItem order,
  ) => order.status == CleaningBookingStatus.awaitingStartVerification;

  static bool isAwaitingWorkerStartConfirmation(
    FetchOrdersUsecaseModelDataItem order,
  ) => order.status == CleaningBookingStatus.awaitingWorkerStartConfirmation;

  static bool isTravelingToCustomer(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.workerAssigned &&
      order.startedTravelAt != null &&
      !isAwaitingStartVerification(order);

  static bool canCompleteWork(String? status) {
    final normalized = (status ?? '').toLowerCase();
    return normalized == CleaningBookingStatus.inProgress ||
        normalized == CleaningBookingStatus.timeExtensionRequested;
  }

  static bool isAwaitingCustomerCompletion(String? status) =>
      (status ?? '').toLowerCase() ==
      CleaningBookingStatus.awaitingCustomerCompletion;

  /// Higher rank means further along the booking lifecycle.
  static int lifecycleRank(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return -1;
    if (normalized == CleaningBookingStatus.pending) return 0;
    if (normalized == CleaningBookingStatus.workerAssigned) return 10;
    if (normalized == CleaningBookingStatus.awaitingStartVerification) {
      return 20;
    }
    if (normalized == CleaningBookingStatus.awaitingWorkerStartConfirmation) {
      return 25;
    }
    if (normalized == CleaningBookingStatus.inProgress) return 30;
    if (normalized == CleaningBookingStatus.timeExtensionRequested) {
      return 35;
    }
    if (normalized == CleaningBookingStatus.awaitingCustomerCompletion) {
      return 40;
    }
    if (normalized == CleaningBookingStatus.completed) return 50;
    if (normalized == CleaningBookingStatus.cancelled) return 60;
    return -1;
  }

  /// True when [incoming] should replace [current] (never downgrade lifecycle).
  static bool shouldPreferIncomingStatus(String? current, String? incoming) {
    if (incoming == null || incoming.trim().isEmpty) return false;
    if (current == null || current.trim().isEmpty) return true;
    return lifecycleRank(incoming) >= lifecycleRank(current);
  }

  static int detailsStepForStatus(String? status) =>
      detailsStepFor(FetchOrdersUsecaseModelDataItem(status: status));

  /// Maps booking status to details wizard step (0–3).
  static int detailsStepFor(FetchOrdersUsecaseModelDataItem order) {
    if (isPending(order)) {
      return 0;
    }
    if (order.status == CleaningBookingStatus.workerAssigned) {
      if (order.startedTravelAt == null) {
        return 1;
      }
      return 2;
    }
    if (isAwaitingStartVerification(order)) {
      return 2;
    }
    if (isAwaitingWorkerStartConfirmation(order)) {
      return 2;
    }
    if (order.status == CleaningBookingStatus.inProgress ||
        order.status == CleaningBookingStatus.timeExtensionRequested ||
        order.status == CleaningBookingStatus.awaitingCustomerCompletion) {
      return 3;
    }
    return 1;
  }

  /// Same loading scope as [OrderCard]: only the tapped list item shows spinner.
  static bool isLoadingForOrderIndex({
    required OrdersState state,
    required int orderIndex,
    required BlocStatus? actionStatus,
  }) => actionStatus == BlocStatus.loading && state.selectedIndex == orderIndex;

  static String statusLabel(FetchOrdersUsecaseModelDataItem order) {
    final status = order.status;
    if (isAcceptedWaiting(order)) return acceptedWaitingLabel(order);
    if (status == CleaningBookingStatus.pending) return 'طلب جديد';
    if (status == CleaningBookingStatus.workerAssigned) {
      return order.startedTravelAt == null ? 'طلب مؤكد' : 'في الطريق';
    }
    if (status == CleaningBookingStatus.awaitingStartVerification) {
      return 'بانتظار التحقق';
    }
    if (status == CleaningBookingStatus.awaitingWorkerStartConfirmation) {
      return 'تم تحقق العميل - ابدأ العمل';
    }
    if (status == CleaningBookingStatus.inProgress) return 'قيد التنفيذ';
    if (status == CleaningBookingStatus.awaitingCustomerCompletion) {
      return 'بانتظار تأكيد العميل';
    }
    if (status == CleaningBookingStatus.timeExtensionRequested) {
      return 'طلب تمديد وقت';
    }
    if (status == CleaningBookingStatus.completed) return 'مكتمل';
    if (status == CleaningBookingStatus.cancelled) return 'ملغي';
    return 'قيد المعالجة';
  }
}
