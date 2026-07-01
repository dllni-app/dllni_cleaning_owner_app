import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';

import '../../../data/models/arrive_model.dart';
import '../../../data/models/cleaning_booking_status.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/complete_order_usecase_use_case.dart';
import '../../../domain/usecases/fetch_order_details_usecase_use_case.dart';
import '../../helpers/order_lifecycle_policy.dart';
import '../../helpers/order_mission_task_mapper.dart';
import '../../helpers/order_work_timer_helper.dart';
import 'mission/completion_message_sheet.dart';
import 'mission/mission_finish_button.dart';
import 'mission/mission_payment_summary_card.dart';
import 'mission/mission_support_button.dart';
import 'mission/mission_task_card.dart';
import 'mission/mission_timer_card.dart';
import 'mission/mission_waiting_customer_card.dart';
import 'mission/waiting_customer_confirmation_sheet.dart';

class OrderDetailsMissionBody extends StatefulWidget {
  const OrderDetailsMissionBody({
    super.key,
    required this.order,
    required this.bloc,
    required this.index,
    required this.services,
    required this.addons,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final OrdersBloc bloc;
  final int index;
  final List<Service> services;
  final List<Addon> addons;

  @override
  State<OrderDetailsMissionBody> createState() =>
      _OrderDetailsMissionBodyState();
}

class _OrderDetailsMissionBodyState extends State<OrderDetailsMissionBody> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  Duration _overdueTime = Duration.zero;
  bool _isWorkTimerAvailable = false;
  bool _isWorkOverdue = false;
  bool _waitingSheetOpen = false;
  String? _lastCompletionMessage;
  String? _workTimerSessionKey;
  final Map<String, bool> _taskState = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _workTimerSessionKey = _resolveWorkTimerSession()?.sessionKey;
    _initTasks();
    _calculateWorkTimer();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant OrderDetailsMissionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) _lastCompletionMessage = null;

    final nextSessionKey = _resolveWorkTimerSession()?.sessionKey;
    final shouldResetTasks = oldWidget.order.id != widget.order.id ||
        oldWidget.services.length != widget.services.length ||
        oldWidget.addons.length != widget.addons.length ||
        nextSessionKey != _workTimerSessionKey;
    if (shouldResetTasks) {
      _workTimerSessionKey = nextSessionKey;
      _initTasks();
    }

    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.status != widget.order.status ||
        oldWidget.order.workStartedAt != widget.order.workStartedAt ||
        oldWidget.order.arrivedAt != widget.order.arrivedAt ||
        oldWidget.order.scheduledDate != widget.order.scheduledDate ||
        oldWidget.order.scheduledTime != widget.order.scheduledTime ||
        oldWidget.order.totalHours != widget.order.totalHours ||
        oldWidget.order.estimatedHours != widget.order.estimatedHours ||
        oldWidget.order.timeWarnings != widget.order.timeWarnings) {
      _calculateWorkTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<MissionTaskItem> get _tasks => OrderMissionTaskMapper.build(
        order: widget.order,
        services: widget.services,
        addons: widget.addons,
      );

  void _initTasks() {
    _taskState.clear();
    for (final entry in _tasks.asMap().entries) {
      _taskState.putIfAbsent(
        OrderMissionTaskMapper.keyFor(entry.value, entry.key),
        () => false,
      );
    }
  }

  bool _isTaskChecked(MissionTaskItem task, int index) {
    return _taskState[OrderMissionTaskMapper.keyFor(task, index)] ?? false;
  }

  void _setTaskChecked(MissionTaskItem task, int index, bool value) {
    setState(() {
      _taskState[OrderMissionTaskMapper.keyFor(task, index)] = value;
    });
  }

  bool get _allTasksChecked {
    final tasks = _tasks;
    return tasks.isNotEmpty &&
        tasks.asMap().entries.every((entry) => _isTaskChecked(
              entry.value,
              entry.key,
            ));
  }

  bool get _isChecklistLocked => _isWaitingCustomer;

  String _effectiveStatus(OrdersState state) {
    final details = state.orderDetailsUsecase?.data;
    if (details?.id == widget.order.id && details?.status != null) {
      return (details!.status ?? '').trim().toLowerCase();
    }
    return (widget.order.status ?? '').trim().toLowerCase();
  }

  bool get _isWaitingCustomer => OrderLifecyclePolicy.isAwaitingCustomerCompletion(
        _effectiveStatus(widget.bloc.state),
      );
  bool get _isExtensionRequested =>
      _effectiveStatus(widget.bloc.state) ==
      CleaningBookingStatus.timeExtensionRequested;
  bool _isWaitingFromState(OrdersState state) =>
      OrderLifecyclePolicy.isAwaitingCustomerCompletion(_effectiveStatus(state));
  bool get _canFinish => widget.order.id != null &&
      OrderLifecyclePolicy.canCompleteWork(_effectiveStatus(widget.bloc.state));

  String? _currentCompletionMessage(OrdersState state) {
    final value = state.completeOrderUsecase?.data?.note ?? _lastCompletionMessage;
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showCompletionMessageSheet() async {
    if (!_canFinish || widget.order.id == null) return;
    final message = await CompletionMessageSheet.show(
      context,
      initialMessage: _lastCompletionMessage,
    );
    if (message == null || widget.order.id == null) return;

    final trimmed = message.trim();
    setState(() => _lastCompletionMessage = trimmed.isEmpty ? null : trimmed);
    widget.bloc.add(
      CompleteOrderUsecaseEvent(
        params: CompleteOrderUsecaseParams(
          id: widget.order.id!,
          completionMessage: trimmed,
        ),
      ),
    );
  }

  Future<void> _showWaitingConfirmationSheet() async {
    if (!mounted || _waitingSheetOpen) return;
    _waitingSheetOpen = true;
    await WaitingCustomerConfirmationSheet.show(
      context,
      onRefresh: () {
        final orderId = widget.order.id;
        if (orderId == null) return;
        widget.bloc.add(
          FetchOrderDetailsUsecaseEvent(
            params: FetchOrderDetailsUsecaseParams(id: orderId),
          ),
        );
      },
    );
    _waitingSheetOpen = false;
  }

  bool _isActiveWorkTimerStatus(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    return normalized == CleaningBookingStatus.inProgress ||
        normalized == CleaningBookingStatus.timeExtensionRequested;
  }

  OrderWorkTimerSession? _resolveWorkTimerSession() {
    return OrderWorkTimerHelper.resolve(
      scheduledDate: widget.order.scheduledDate,
      scheduledTime: widget.order.scheduledTime,
      workStartedAt: widget.order.workStartedAt,
      arrivedAt: widget.order.arrivedAt,
      totalHours: widget.order.totalHours,
      estimatedHours: widget.order.estimatedHours,
      timeWarnings: widget.order.timeWarnings,
    );
  }

  void _setTimerUnavailable() {
    if (!mounted) return;
    setState(() {
      _isWorkTimerAvailable = false;
      _isWorkOverdue = false;
      _remainingTime = Duration.zero;
      _overdueTime = Duration.zero;
    });
  }

  void _calculateWorkTimer() {
    final status = _effectiveStatus(widget.bloc.state);
    if (!_isActiveWorkTimerStatus(status)) {
      _setTimerUnavailable();
      return;
    }
    final session = _resolveWorkTimerSession();
    if (session == null) {
      _setTimerUnavailable();
      return;
    }
    final diff = session.expectedFinishAt.difference(DateTime.now());
    final isOverdue = diff.isNegative;
    if (!mounted) return;
    setState(() {
      _isWorkTimerAvailable = true;
      _isWorkOverdue = isOverdue;
      _remainingTime = isOverdue ? Duration.zero : diff;
      _overdueTime = isOverdue ? diff.abs() : Duration.zero;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateWorkTimer(),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _serviceDate() {
    final raw = widget.order.scheduledDate;
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('yyyy/MM/dd', 'en').format(date);
  }

  List<Color> get _timerGradientColors {
    if (_isWaitingCustomer) {
      return const <Color>[Color(0xff1E2A78), Color(0xff283593)];
    }
    if (_isExtensionRequested) {
      return const <Color>[Color(0xff7C3AED), Color(0xff6D28D9)];
    }
    if (_isWorkOverdue) {
      return const <Color>[Color(0xffD97706), Color(0xffF59E0B)];
    }
    return const <Color>[Color(0xff1DBCC8), Color(0xff10A7B2)];
  }

  String get _missionStatusText {
    if (_isWaitingCustomer) return 'بانتظار تأكيد العميل';
    if (_isExtensionRequested) return 'طلب تمديد وقت';
    if (_isWorkOverdue) return 'العمل متأخر';
    return 'العمل قيد التنفيذ';
  }

  String get _timerTitleText {
    if (_isWaitingCustomer) return 'تم إرسال طلب إنهاء العمل للعميل';
    if (_isExtensionRequested) return 'بانتظار الرد على طلب التمديد';
    if (!_isWorkTimerAvailable) return 'وقت العمل غير متوفر لهذا الطلب';
    if (_isWorkOverdue) return 'انتهى الوقت المحدد للعمل';
    return 'الوقت المتبقي لإنهاء العمل';
  }

  String get _timerValueText {
    if (_isWaitingCustomer) return 'بانتظار تأكيد العميل';
    if (!_isWorkTimerAvailable) return '--:--:--';
    if (_isWorkOverdue) return 'تأخير: ${_formatDuration(_overdueTime)}';
    return _formatDuration(_remainingTime);
  }

  String? get _timerHelperText {
    if (_isWaitingCustomer) return 'تم قفل قائمة المهام بعد إرسال طلب الإنهاء.';
    if (_isExtensionRequested) return 'لا يتم قبول أو رفض التمديد تلقائياً.';
    if (!_isWorkTimerAvailable) return null;
    if (_isWorkOverdue) {
      return 'يرجى إنهاء العمل وإرسال طلب التأكيد للعميل عند الانتهاء.';
    }
    return null;
  }

  String get _taskListHintText => _isChecklistLocked
      ? 'قائمة المهام مقفلة لأن طلب إنهاء العمل قد تم إرساله.'
      : 'تحديد المهام التي قمت بتنفيذها';
  String get _finishButtonText =>
      _isWaitingCustomer ? 'تم إرسال طلب الإنهاء' : 'إنهاء العمل';

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) =>
          (previous.completeOrderUsecaseStatus !=
                  current.completeOrderUsecaseStatus &&
              current.completeOrderUsecaseStatus == BlocStatus.success) ||
          (!_isWaitingFromState(previous) && _isWaitingFromState(current)),
      listener: (context, state) => unawaited(_showWaitingConfirmationSheet()),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 14.w),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: AppText.headlineMedium(
                    'تفاصيل الطلب ${widget.order.bookingNumber ?? ''}',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MissionTimerCard(
                      serviceDate: _serviceDate(),
                      statusText: _missionStatusText,
                      titleText: _timerTitleText,
                      valueText: _timerValueText,
                      helperText: _timerHelperText,
                      gradientColors: _timerGradientColors,
                    ),
                    14.verticalSpace,
                    MissionTaskCard(
                      tasks: _tasks,
                      hintText: _taskListHintText,
                      isChecklistLocked: _isChecklistLocked,
                      allTasksChecked: _allTasksChecked,
                      isChecked: _isTaskChecked,
                      onChanged: _setTaskChecked,
                    ),
                    14.verticalSpace,
                    MissionPaymentSummaryCard(order: widget.order),
                    _buildWaitingCustomerCard(),
                    14.verticalSpace,
                    _buildFinishButton(),
                    10.verticalSpace,
                    MissionSupportButton(orderId: widget.order.id),
                    20.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingCustomerCard() {
    return BlocBuilder<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      builder: (context, state) {
        return MissionWaitingCustomerCard(
          visible: _isWaitingCustomer,
          completionMessage: _currentCompletionMessage(state),
        );
      },
    );
  }

  Widget _buildFinishButton() {
    return BlocBuilder<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final loading = state.completeOrderUsecaseStatus == BlocStatus.loading;
        return MissionFinishButton(
          loading: loading,
          enabled: !_isChecklistLocked && _canFinish && _allTasksChecked && !loading,
          text: _finishButtonText,
          onPressed: () => unawaited(_showCompletionMessageSheet()),
        );
      },
    );
  }
}
