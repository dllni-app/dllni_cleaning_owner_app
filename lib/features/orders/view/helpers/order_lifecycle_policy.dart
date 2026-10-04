import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/app_config.dart';

import '../../data/models/cleaning_booking_status.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../../data/models/worker_booking_schedule_model.dart';
import '../manager/bloc/orders_bloc.dart';
import 'cleaning_worker_order_status.dart';
import 'dedicated_order_helper.dart';

enum OrderDetailsUiState {
  newOrder,
  acceptedWaitingTeam,
  readyToStartTravel,
  traveling,
  awaitingCustomerCode,
  awaitingWorkerStartConfirmation,
  startApprovedWaitingTeam,
  inProgress,
  extensionPendingWorkerDecision,
  awaitingCustomerCompletion,
  underDispute,
  completed,
  cancelled,
  unknown,
}

extension OrderDetailsUiStateX on OrderDetailsUiState {
  bool get usesDetailsBody {
    switch (this) {
      case OrderDetailsUiState.newOrder:
      case OrderDetailsUiState.acceptedWaitingTeam:
      case OrderDetailsUiState.readyToStartTravel:
      case OrderDetailsUiState.unknown:
        return true;
      default:
        return false;
    }
  }

  bool get usesMapBody {
    switch (this) {
      case OrderDetailsUiState.traveling:
      case OrderDetailsUiState.awaitingCustomerCode:
      case OrderDetailsUiState.awaitingWorkerStartConfirmation:
      case OrderDetailsUiState.startApprovedWaitingTeam:
        return true;
      default:
        return false;
    }
  }

  bool get usesMissionBody => !usesDetailsBody && !usesMapBody;

  bool get isActiveWork => this == OrderDetailsUiState.inProgress;

  bool get isWaitingCustomer =>
      this == OrderDetailsUiState.awaitingCustomerCompletion;

  bool get isExtensionPending =>
      this == OrderDetailsUiState.extensionPendingWorkerDecision;

  bool get isDispute => this == OrderDetailsUiState.underDispute;

  bool get isFinal =>
      this == OrderDetailsUiState.completed ||
      this == OrderDetailsUiState.cancelled;
}

/// Single source of truth for order action visibility (card + details screens).
class OrderLifecyclePolicy {
  OrderLifecyclePolicy._();

  static const String startTravelUnavailableMessage =
      'يمكن بدء التوجه إلى موقع الطلب قبل الموعد بساعة واحدة.';
  static const String orderNoLongerAvailableMessage =
      'تم قبول هذا الطلب مسبقاً أو لم يعد متاحاً.';

  static bool isPending(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.pending;

  static bool isTimeExtensionRequested(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.timeExtensionRequested;

  static bool isCustomerDataHidden(FetchOrdersUsecaseModelDataItem order) =>
      isPending(order) && !hasCurrentWorkerAccepted(order);

  static bool hasCurrentWorkerAccepted(FetchOrdersUsecaseModelDataItem order) {
    final assignment = order.myAssignment;
    return isWorkerAcceptedAssignmentStatusValue(order.workerOrderStatus) ||
        isWorkerAcceptedAssignmentStatusValue(assignment?.status) ||
        (assignment?.acceptedAt?.isNotEmpty ?? false);
  }

  static bool hasCurrentWorkerRejectedOrClosed(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    final assignment = order.myAssignment;
    return isWorkerRejectedOrClosedAssignmentStatusValue(order.workerOrderStatus) ||
        isWorkerRejectedOrClosedAssignmentStatusValue(assignment?.status);
  }

  static bool isAvailableNewOrderForCurrentWorker(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    return isPending(order) &&
        !hasCurrentWorkerAccepted(order) &&
        !hasCurrentWorkerRejectedOrClosed(order);
  }

  /// Auto-prompt (bottom sheet) only for orders dedicated to this worker.
  static bool isDedicatedAvailableNewOrderForCurrentWorker(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    return isAvailableNewOrderForCurrentWorker(order) &&
        DedicatedOrderHelper.isDedicatedToCurrentUser(order.preferredWorkerId);
  }

  static bool isAcceptedWaiting(FetchOrdersUsecaseModelDataItem order) {
    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.accepted:
      case CleaningWorkerOrderStatus.acceptedWaitingTeam:
      case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
        return true;
      default:
        break;
    }
    return isPending(order) && hasCurrentWorkerAccepted(order);
  }

  static OrderDetailsUiState detailsUiStateFor(
    FetchOrdersUsecaseModelDataItem order,
  ) {
    final status = (order.status ?? '').trim().toLowerCase();
    final workerStatus = order.effectiveWorkerStatus;

    switch (status) {
      case CleaningBookingStatus.cancelled:
        return OrderDetailsUiState.cancelled;
      case CleaningBookingStatus.completed:
        return OrderDetailsUiState.completed;
      case CleaningBookingStatus.underDispute:
        return OrderDetailsUiState.underDispute;
      case CleaningBookingStatus.awaitingCustomerCompletion:
        return OrderDetailsUiState.awaitingCustomerCompletion;
      case CleaningBookingStatus.timeExtensionRequested:
        return OrderDetailsUiState.extensionPendingWorkerDecision;
      case CleaningBookingStatus.inProgress:
        return OrderDetailsUiState.inProgress;
      case CleaningBookingStatus.awaitingWorkerStartConfirmation:
        return workerStatus == CleaningWorkerOrderStatus.startApproved
            ? OrderDetailsUiState.startApprovedWaitingTeam
            : OrderDetailsUiState.awaitingWorkerStartConfirmation;
      case CleaningBookingStatus.awaitingStartVerification:
        return OrderDetailsUiState.awaitingCustomerCode;
      case CleaningBookingStatus.workerAssigned:
        return order.startedTravelAt == null
            ? OrderDetailsUiState.readyToStartTravel
            : OrderDetailsUiState.traveling;
      case CleaningBookingStatus.pending:
        return hasCurrentWorkerAccepted(order)
            ? OrderDetailsUiState.acceptedWaitingTeam
            : OrderDetailsUiState.newOrder;
      default:
        return OrderDetailsUiState.unknown;
    }
  }

  static bool canAcceptReject(FetchOrdersUsecaseModelDataItem order) =>
      isAvailableNewOrderForCurrentWorker(order);

  static bool canStartTravel(FetchOrdersUsecaseModelDataItem order) =>
      order.status == CleaningBookingStatus.workerAssigned &&
      order.startedTravelAt == null;

  static bool canStartTravelForSession(WorkerBookingSessionModel session) {
    if (session.isTerminal) return false;

    final assignment = session.assignment;
    if (assignment != null) {
      final assignmentStatus = assignment.status?.trim().toLowerCase();

      if (const <String>{
        'rejected',
        'withdrawn',
        'cancelled',
        'completed',
      }.contains(assignmentStatus)) {
        return false;
      }

      if (assignment.startedTravelAt?.trim().isNotEmpty == true ||
          assignment.arrivedAt?.trim().isNotEmpty == true ||
          assignment.workStartedAt?.trim().isNotEmpty == true) {
        return false;
      }

      // Multi-worker sessions expose aggregate session timestamps. Another
      // worker may already have started travel, so only this worker's
      // assignment decides whether "أنا في الطريق" should remain available.
      if (assignmentStatus == 'accepted' ||
          assignmentStatus == 'accepted_waiting_for_order_start') {
        return true;
      }

      return session.canStartTravel;
    }

    if (session.startedTravelAt?.trim().isNotEmpty == true ||
        session.arrivedAt?.trim().isNotEmpty == true ||
        session.workStartedAt?.trim().isNotEmpty == true) {
      return false;
    }

    return session.canStartTravel;
  }

  static bool isStartTravelWithinAllowedWindow(
    FetchOrdersUsecaseModelDataItem order, {
    DateTime? now,
    bool? enforceWindow,
  }) {
    if (!(enforceWindow ?? AppConfig.enforceStartTravelWindow)) return true;

    final scheduledAt = _scheduledDateTime(order);
    if (scheduledAt == null) return true;

    final currentTime = _toWallClockMinute(now ?? DateTime.now());
    final scheduledMinute = _toWallClockMinute(scheduledAt);
    return !scheduledMinute.isAfter(
      currentTime.add(const Duration(hours: 1)),
    );
  }

  static bool isSessionStartTravelWithinAllowedWindow(
    WorkerBookingSessionModel session, {
    DateTime? now,
    bool? enforceWindow,
  }) {
    if (!(enforceWindow ?? AppConfig.enforceStartTravelWindow)) return true;

    final scheduledAt = _sessionScheduledDateTime(session);
    if (scheduledAt == null) return true;

    final currentTime = _toWallClockMinute(now ?? DateTime.now());
    final scheduledMinute = _toWallClockMinute(scheduledAt);
    return !scheduledMinute.isAfter(
      currentTime.add(const Duration(hours: 1)),
    );
  }

  static DateTime? _sessionScheduledDateTime(
    WorkerBookingSessionModel session,
  ) {
    final date = session.date;
    if (date == null) return null;

    return _buildWallClockDateTime(
      year: date.year,
      month: date.month,
      day: date.day,
      rawTime: session.time,
    );
  }

  static DateTime? _scheduledDateTime(FetchOrdersUsecaseModelDataItem order) {
    final rawDate = order.scheduledDate?.trim();
    if (rawDate == null || rawDate.isEmpty) return null;

    final dateMatch = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})',
    ).firstMatch(rawDate);
    if (dateMatch == null) return null;

    final year = int.tryParse(dateMatch.group(1)!);
    final month = int.tryParse(dateMatch.group(2)!);
    final day = int.tryParse(dateMatch.group(3)!);
    if (year == null || month == null || day == null) return null;

    return _buildWallClockDateTime(
      year: year,
      month: month,
      day: day,
      rawTime: order.scheduledTime,
    );
  }

  static DateTime? _buildWallClockDateTime({
    required int year,
    required int month,
    required int day,
    String? rawTime,
  }) {
    final value = rawTime?.trim();
    if (value == null || value.isEmpty) {
      return DateTime(year, month, day);
    }

    final clockValue = value.contains('T') ? value.split('T').last : value;
    final timeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(clockValue);
    if (timeMatch == null) {
      return DateTime(year, month, day);
    }

    final hour = int.tryParse(timeMatch.group(1)!);
    final minute = int.tryParse(timeMatch.group(2)!);
    final second = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return null;
    }

    // scheduledDate/scheduledTime are booking wall-clock fields. Ignore any
    // timezone suffix attached to the time string so a value such as
    // "13:30:00Z" is still treated as the displayed 13:30 booking time.
    return DateTime(year, month, day, hour, minute, second);
  }

  static DateTime _toWallClockMinute(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  static bool canCancel(FetchOrdersUsecaseModelDataItem order) =>
      canStartTravel(order) &&
      order.id != null &&
      (order.bookingNumber?.trim().isNotEmpty ?? false);

  static bool showFollowOnly(FetchOrdersUsecaseModelDataItem order) =>
      !canAcceptReject(order) && !canStartTravel(order);

  static String teamStateTitle(FetchOrdersUsecaseModelDataItem order) {
    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.accepted:
      case CleaningWorkerOrderStatus.acceptedWaitingTeam:
        return 'تم قبول الطلب';
      case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
        return 'بانتظار بدء الطلب';
      case CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation:
        return 'بانتظار بدء العمل';
      case CleaningWorkerOrderStatus.startApproved:
        return 'بانتظار باقي العمال';
      case CleaningWorkerOrderStatus.rejected:
        return 'تم رفض الطلب';
      case CleaningWorkerOrderStatus.withdrawn:
        return 'تم الانسحاب من الطلب';
      default:
        return order.effectiveWorkerStatusLabel;
    }
  }

  static String? teamStateDescription(FetchOrdersUsecaseModelDataItem order) {
    final accepted =
        order.acceptedWorkersCount ?? order.workerAcceptance?.accepted ?? 0;
    final required =
        order.requiredWorkersCount ??
        order.workerAcceptance?.required ??
        order.numberOfWorkers ??
        1;
    final pending =
        order.pendingWorkersCount ?? (required - accepted).clamp(0, required);

    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.accepted:
      case CleaningWorkerOrderStatus.acceptedWaitingTeam:
        return 'تم قبولك ضمن الفريق. بانتظار اكتمال عدد العمال ($accepted من $required).';
      case CleaningWorkerOrderStatus.acceptedWaitingForOrderStart:
        if (order.numberOfWorkers == null || order.numberOfWorkers == 1) {
          return null;
        }
        if (accepted == required) {
          return 'اكتمل الفريق. سيتم بدء خطوات الوصول والتحقق عند موعد الطلب.';
        }
        return 'تم قبولك ضمن الفريق. بانتظار اكتمال عدد العمال ($accepted من $required).';
      case CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation:
        return 'أكد العميل رمز الوصول. اضغط بدء العمل للمتابعة.';
      case CleaningWorkerOrderStatus.startApproved:
        return 'تم تأكيد بدء العمل من طرفك. بانتظار باقي العمال لبدء الطلب.';
      default:
        return pending > 0 ? 'بانتظار $pending عامل لإكمال الفريق.' : '';
    }
  }

  static String acceptedWaitingLabel(FetchOrdersUsecaseModelDataItem order) {
    return teamStateTitle(order);
  }

  static String? acceptedWaitingMessage(FetchOrdersUsecaseModelDataItem order) {
    final description = teamStateDescription(order);
    if (description == null) return null;
    if (description.isEmpty) return acceptedWaitingMessageLegacy(order);
    return description;
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
    return normalized == CleaningBookingStatus.inProgress;
  }

  static bool canRespondToExtension(String? status) =>
      (status ?? '').toLowerCase() ==
      CleaningBookingStatus.timeExtensionRequested;

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
  }) =>
      actionStatus == BlocStatus.loading && state.selectedIndex == orderIndex;

  static String statusLabel(FetchOrdersUsecaseModelDataItem order) {
    if (isAcceptedWaiting(order)) return acceptedWaitingLabel(order);

    switch (order.effectiveWorkerStatus) {
      case CleaningWorkerOrderStatus.pending:
        return 'طلب جديد';
      case CleaningWorkerOrderStatus.accepted:
        return 'تم قبول الطلب';
      case CleaningWorkerOrderStatus.workerAssigned:
        return order.startedTravelAt == null ? 'طلب مؤكد' : 'في الطريق';
      case CleaningWorkerOrderStatus.awaitingStartVerification:
        return 'بانتظار التحقق';
      case CleaningWorkerOrderStatus.awaitingWorkerStartConfirmation:
        return 'تم تحقق العميل - ابدأ العمل';
      case CleaningWorkerOrderStatus.startApproved:
        return 'بانتظار باقي العمال';
      case CleaningWorkerOrderStatus.rejected:
        return 'تم رفض الطلب';
      case CleaningWorkerOrderStatus.withdrawn:
        return 'تم الانسحاب';
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