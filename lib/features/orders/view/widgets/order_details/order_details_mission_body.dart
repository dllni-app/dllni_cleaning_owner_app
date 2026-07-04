import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';

import '../../../data/models/arrive_model.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/accept_extension_usecase_use_case.dart';
import '../../../domain/usecases/complete_order_usecase_use_case.dart';
import '../../../domain/usecases/fetch_order_details_usecase_use_case.dart';
import '../../../domain/usecases/reject_extension_usecase_use_case.dart';
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
  State<OrderDetailsMissionBody> createState() => _OrderDetailsMissionBodyState();
}

class _OrderDetailsMissionBodyState extends State<OrderDetailsMissionBody> {
  Timer? _timer;
  OrderWorkTimerSession? _timerSession;
  int? _timerOrderId;
  Duration _elapsedTime = Duration.zero;
  bool _isWorkTimerAvailable = false;
  bool _isSessionFinished = false;
  bool _waitingSheetOpen = false;
  String? _lastCompletionMessage;
  final Map<String, bool> _taskState = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _initTasks();
    _syncTimerSession(resetCurrentSession: true);
    _calculateWorkTimer();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant OrderDetailsMissionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _lastCompletionMessage = null;
      _syncTimerSession(resetCurrentSession: true);
    }

    final shouldResetTasks = oldWidget.order.id != widget.order.id || oldWidget.services.length != widget.services.length || oldWidget.addons.length != widget.addons.length;
    if (shouldResetTasks) _initTasks();

    if (oldWidget.order.id != widget.order.id || oldWidget.order.status != widget.order.status || oldWidget.order.totalHours != widget.order.totalHours || oldWidget.order.estimatedHours != widget.order.estimatedHours || oldWidget.order.timeWarnings != widget.order.timeWarnings) {
      _syncTimerSession();
      _calculateWorkTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  OrderDetailsUiState get _uiState => OrderLifecyclePolicy.detailsUiStateFor(widget.order);

  List<MissionTaskItem> get _tasks => OrderMissionTaskMapper.build(order: widget.order, services: widget.services, addons: widget.addons);

  void _initTasks() {
    _taskState.clear();
    for (final entry in _tasks.asMap().entries) {
      _taskState.putIfAbsent(OrderMissionTaskMapper.keyFor(entry.value, entry.key), () => false);
    }
  }

  bool _isTaskChecked(MissionTaskItem task, int index) => _taskState[OrderMissionTaskMapper.keyFor(task, index)] ?? false;

  void _setTaskChecked(MissionTaskItem task, int index, bool value) {
    setState(() => _taskState[OrderMissionTaskMapper.keyFor(task, index)] = value);
  }

  bool get _allTasksChecked {
    final tasks = _tasks;
    if (tasks.isEmpty) return true;
    return tasks.asMap().entries.every((entry) => _isTaskChecked(entry.value, entry.key));
  }

  bool get _isChecklistLocked => !_uiState.isActiveWork;
  bool get _canFinish => widget.order.id != null && _uiState.isActiveWork;

  String _effectiveStatus(OrdersState state) {
    final details = state.orderDetailsUsecase?.data;
    if (details?.id == widget.order.id && details?.status != null) return (details!.status ?? '').trim().toLowerCase();
    return (widget.order.status ?? '').trim().toLowerCase();
  }

  bool _isWaitingFromState(OrdersState state) => OrderLifecyclePolicy.isAwaitingCustomerCompletion(_effectiveStatus(state));

  String? _currentCompletionMessage(OrdersState state) {
    final value = state.completeOrderUsecase?.data?.note ?? _lastCompletionMessage;
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<Map<String, Object?>> _checkedPayload(MissionTaskType type) {
    final result = <Map<String, Object?>>[];
    for (final entry in _tasks.asMap().entries) {
      final task = entry.value;
      if (task.type != type || !_isTaskChecked(task, entry.key)) continue;
      result.add(task.toCompletionPayload());
    }
    return result;
  }

  Future<void> _showCompletionMessageSheet() async {
    if (!_canFinish || widget.order.id == null) return;
    final message = await CompletionMessageSheet.show(context, initialMessage: _lastCompletionMessage);
    if (message == null || widget.order.id == null) return;

    final trimmed = message.trim();
    setState(() => _lastCompletionMessage = trimmed.isEmpty ? null : trimmed);
    widget.bloc.add(
      CompleteOrderUsecaseEvent(
        params: CompleteOrderUsecaseParams(
          id: widget.order.id!,
          completionMessage: trimmed,
          cleaningServices: _checkedPayload(MissionTaskType.service),
          propertiesRooms: _checkedPayload(MissionTaskType.room),
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
        widget.bloc.add(FetchOrderDetailsUsecaseEvent(params: FetchOrderDetailsUsecaseParams(id: orderId)));
      },
    );
    _waitingSheetOpen = false;
  }

  void _syncTimerSession({bool resetCurrentSession = false}) {
    if (!_uiState.isActiveWork) {
      _timerSession = null;
      _timerOrderId = null;
      return;
    }
    final extensionSeed = OrderWorkTimerHelper.latestAcceptedExtensionSeed(widget.order.timeWarnings);
    if (extensionSeed != null) {
      if (resetCurrentSession || _timerSession?.sessionKey != extensionSeed.sessionKey) {
        _timerSession = OrderWorkTimerHelper.startExtensionSession(now: DateTime.now(), seed: extensionSeed);
        _timerOrderId = widget.order.id;
      }
      return;
    }
    final maxDuration = OrderWorkTimerHelper.originalBookingDuration(totalHours: widget.order.totalHours, estimatedHours: widget.order.estimatedHours);
    if (maxDuration == null) {
      _timerSession = null;
      _timerOrderId = null;
      return;
    }
    if (resetCurrentSession || _timerSession == null || _timerSession!.isExtension || _timerOrderId != widget.order.id) {
      _timerSession = OrderWorkTimerHelper.startOriginalSession(now: DateTime.now(), maxDuration: maxDuration);
      _timerOrderId = widget.order.id;
    }
  }

  void _resetExtensionSessionFromState(OrdersState state) {
    final data = state.acceptExtensionUsecase?.data;
    final minutes = data?.approvedMinutes;
    if (minutes == null || minutes <= 0) return;
    final seed = AcceptedExtensionTimerSeed(id: data?.id, minutes: minutes);
    if (_timerSession?.sessionKey == seed.sessionKey) return;
    _timerSession = OrderWorkTimerHelper.startExtensionSession(now: DateTime.now(), seed: seed);
    _timerOrderId = widget.order.id;
    _calculateWorkTimer();
  }

  void _setTimerUnavailable() {
    if (!mounted) return;
    setState(() {
      _isWorkTimerAvailable = false;
      _isSessionFinished = false;
      _elapsedTime = Duration.zero;
    });
  }

  void _calculateWorkTimer() {
    if (!_uiState.isActiveWork) {
      _setTimerUnavailable();
      return;
    }
    _syncTimerSession();
    final session = _timerSession;
    if (session == null) {
      _setTimerUnavailable();
      return;
    }
    final now = DateTime.now();
    final finished = session.isFinishedAt(now);
    final elapsed = session.elapsedAt(now);
    if (!mounted) return;
    setState(() {
      _isWorkTimerAvailable = true;
      _isSessionFinished = finished;
      _elapsedTime = finished ? session.maxDuration : elapsed;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateWorkTimer());
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

  List<Color> get _timerGradientColors => const <Color>[Color(0xff1DBCC8), Color(0xff10A7B2)];

  String get _missionStatusText {
    if (_uiState.isWaitingCustomer) return 'بانتظار تأكيد العميل';
    if (_uiState.isExtensionPending) return 'طلب تمديد وقت';
    if (_uiState.isDispute) return 'الطلب قيد المراجعة';
    if (_uiState == OrderDetailsUiState.completed) return 'الطلب مكتمل';
    if (_uiState == OrderDetailsUiState.cancelled) return 'الطلب ملغي';
    if (_isSessionFinished) return 'انتهى وقت الجلسة';
    return 'العمل قيد التنفيذ';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) => previous.completeOrderUsecase?.status != current.completeOrderUsecase?.status || previous.orderDetailsUsecase?.status != current.orderDetailsUsecase?.status || previous.acceptExtensionUsecase?.status != current.acceptExtensionUsecase?.status,
      listener: (context, state) {
        if (state.completeOrderUsecase?.status == BlocStatus.failure) AppToast.showToast(context: context, message: state.completeOrderUsecase?.failure?.message ?? 'تعذر إنهاء الطلب', type: ToastificationType.error);
        if (state.completeOrderUsecase?.status == BlocStatus.success || _isWaitingFromState(state)) unawaited(_showWaitingConfirmationSheet());
        if (state.acceptExtensionUsecase?.status == BlocStatus.success) _resetExtensionSessionFromState(state);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MissionTimerCard(statusText: _missionStatusText, elapsedText: _formatDuration(_elapsedTime), serviceDate: _serviceDate(), gradientColors: _timerGradientColors, isWorkTimerAvailable: _isWorkTimerAvailable),
          SizedBox(height: 12.h),
          MissionTaskCard(tasks: _tasks, isLocked: _isChecklistLocked, isTaskChecked: _isTaskChecked, onChanged: _setTaskChecked),
          SizedBox(height: 12.h),
          MissionPaymentSummaryCard(order: widget.order),
          SizedBox(height: 12.h),
          MissionSupportButton(order: widget.order, bloc: widget.bloc),
          SizedBox(height: 12.h),
          if (_uiState.isWaitingCustomer) MissionWaitingCustomerCard(message: _currentCompletionMessage(context.read<OrdersBloc>().state)),
          if (_uiState.isActiveWork) MissionFinishButton(isEnabled: _canFinish && _allTasksChecked, isLoading: context.select((OrdersBloc bloc) => bloc.state.completeOrderUsecase?.status == BlocStatus.loading), onPressed: _showCompletionMessageSheet),
        ],
      ),
    );
  }
}
