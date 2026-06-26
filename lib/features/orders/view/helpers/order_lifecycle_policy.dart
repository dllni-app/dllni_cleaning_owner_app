import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/app_config.dart';

import '../../data/models/cleaning_booking_status.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../manager/bloc/orders_bloc.dart';
import 'cleaning_worker_order_status.dart';

/// Single source of truth for order action visibility (card + details screens).
class OrderLifecyclePolicy {
  OrderLifecyclePolicy._();

  static const String startTravelUnavailableMessage =
      'لا يمكنك اجراء هذه العملية حاليا';

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

  static bool isAcceptedWaiting(FetchOrdersUsecaseModelDataItem order) {
    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.acceptedWaitingTeam:
      case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
        return true;
      default:
        break;
    }
    return isPending(order) && hasCurrentWorkerAccepted(order);
  }

  static bool canAcceptReject(FetchOrdersUsecaseModelDataItem order) =>
      isPending(order) && !hasCurrentWorkerAccepted(order);

  static bool canStartTravel(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.workerAssigned &&
      order.startedTravelAt == null;

  static bool isStartTravelWithinAllowedWindow(
    FetchOrdersUsecaseModelDataItem order, {
    DateTime? now,
    bool? enforceWindow,
  }) {
    if (!(enforceWindow ?? AppConfig.enforceStartTravelWindow)) return true;

    final scheduledAt = _scheduledDateTime(order);
    if (scheduledAt == null) return true;

    final currentTime = now ?? DateTime.now();
    return !scheduledAt.isAfter(currentTime.add(const Duration(hours: 1)));
  }

  static DateTime? _scheduledDateTime(FetchOrdersUsecaseModelDataItem order) {
    final rawDate = order.scheduledDate?.trim();
    if (rawDate == null || rawDate.isEmpty) return null;

    final rawTime = order.scheduledTime?.trim();
    if (rawTime == null || rawTime.isEmpty) {
      return DateTime.tryParse(rawDate);
    }

    final datePart = rawDate.split(RegExp(r'[T ]')).first;
    final timePart = rawTime.contains('T') ? rawTime.split('T').last : rawTime;
    return DateTime.tryParse('${datePart}T$timePart');
  }

  static bool canCancel(FetchOrdersUsecaseModelDataItem order) =>
      canStartTravel(order) &&
      order.id != null &&
      (order.bookingNumber?.trim().isNotEmpty ?? false);

  static bool showFollowOnly(FetchOrdersUsecaseModelDataItem order) =>
      !canAcceptReject(order) && !canStartTravel(order);

  static String teamStateTitle(FetchOrdersUsecaseModelDataItem order) {
    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.acceptedWaitingTeam:
        return 'تم قبول الطلب';
      case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
        return 'بانتظار بدء الطلب';
      case CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation:
        return 'بانتظار بدء العمل';
      default:
        return order.effectiveWorkerStatusLabel;
    }
  }

  static String teamStateDescription(FetchOrdersUsecaseModelDataItem order) {
    final accepted =
        order.acceptedWorkersCount ?? order.workerAcceptance?.accepted ?? 0;
    final required =
        order.requiredWorkersCount ??
        order.workerAcceptance?.required ??
        order.numberOfWorkers ??
        1;
    final pending =
        order.pendingWorkersCount ??
        (required - accepted).clamp(0, required);

    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.acceptedWaitingTeam:
        return 'تم قبولك ضمن الفريق. بانتظار اكتمال عدد العمال ($accepted من $required).';
      case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
        return 'اكتمل الفريق. سيتم بدء خطوات الوصول والتحقق عند موعد الطلب.';
      case CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation:
        return 'أكد العميل رمز الوصول. اضغط بدء العمل للمتابعة.';
      default:
        return pending > 0 ? 'بانتظار $pending عامل لإكمال الفريق.' : '';
    }
  }

  static String acceptedWaitingLabel(FetchOrdersUsecaseModelDataItem order) {
    return teamStateTitle(order);
  }

  static String acceptedWaitingMessage(FetchOrdersUsecaseModelDataItem order) {
    final description = teamStateDescription(order);
    if (description.isNotEmpty) return description;
    return acceptedWaitingMessageLegacy(order);
  }

  static String acceptedWaitingMessageLegacy(
    FetchOrdersUsecaseModelDataItem order,
  ) {
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
  ) =>
      order.effectiveWorkerStatus ==
          CleaningWorkerOrderStatus.awaitingStartVerification ||
      order.status == CleaningBookingStatus.awaitingStartVerification;

  static bool isAwaitingWorkerStartConfirmation(
    FetchOrdersUsecaseModelDataItem order,
  ) =>
      order.effectiveWorkerStatus ==
          CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation ||
      order.status == CleaningBookingStatus.awaitingWorkerStartConfirmation;

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
    if (normalized == CleaningBookingStatus.underDispute) return 45;
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

  /// Extension accept returns to in-progress even though rank is lower.
  static bool shouldApplyRealtimeStatus({
    required String? currentStatus,
    required String? incomingStatus,
    String? decision,
  }) {
    final normalizedDecision = (decision ?? '').trim().toLowerCase();
    final normalizedIncoming = (incomingStatus ?? '').trim().toLowerCase();
    final normalizedCurrent = (currentStatus ?? '').trim().toLowerCase();

    if (normalizedDecision == 'extension_accepted' &&
        normalizedCurrent == CleaningBookingStatus.timeExtensionRequested &&
        normalizedIncoming == CleaningBookingStatus.inProgress) {
      return true;
    }

    if (normalizedCurrent == CleaningBookingStatus.timeExtensionRequested &&
        normalizedIncoming == CleaningBookingStatus.inProgress) {
      return true;
    }

    return shouldPreferIncomingStatus(currentStatus, incomingStatus);
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
        order.status == CleaningBookingStatus.awaitingCustomerCompletion ||
        order.status == CleaningBookingStatus.underDispute) {
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
    if (isAcceptedWaiting(order)) return acceptedWaitingLabel(order);

    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.pending:
        return 'طلب جديد';
      case CleaningWorkerOrderStatus.workerAssigned:
        return order.startedTravelAt == null ? 'طلب مؤكد' : 'في الطريق';
      case CleaningWorkerOrderStatus.awaitingStartVerification:
        return 'بانتظار التحقق';
      case CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation:
        return 'تم تحقق العميل - ابدأ العمل';
      case CleaningWorkerOrderStatus.inProgress:
        return 'قيد التنفيذ';
      case CleaningWorkerOrderStatus.awaitingCustomerCompletion:
        return 'بانتظار تأكيد العميل';
      case CleaningWorkerOrderStatus.timeExtensionRequested:
        return 'طلب تمديد وقت';
      case CleaningWorkerOrderStatus.underDispute:
        return 'قيد المراجعة';
      case CleaningWorkerOrderStatus.completed:
        return 'مكتمل';
      case CleaningWorkerOrderStatus.cancelled:
        return 'ملغي';
      default:
        return order.effectiveWorkerStatusLabel;
    }
  }
}
