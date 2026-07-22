import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
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
import 'mission/mission_services_info_card.dart';
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

    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.roomAssignments?.length !=
            widget.order.roomAssignments?.length) {
      _initTasks();
    }

    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.status != widget.order.status ||
        oldWidget.order.totalHours != widget.order.totalHours ||
        oldWidget.order.myAssignment?.totalHours !=
            widget.order.myAssignment?.totalHours ||
        oldWidget.order.estimatedHours != widget.order.estimatedHours ||
        oldWidget.order.timeWarnings != widget.order.timeWarnings) {
      _syncTimerSession();
      _calculateWorkTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  OrderDetailsUiState get _uiState =>
      OrderLifecyclePolicy.detailsUiStateFor(widget.order);

  List<MissionTaskItem> get _tasks =>
      OrderMissionTaskMapper.build(order: widget.order);

  List<MissionTaskItem> get _servicesInfo =>
      OrderMissionTaskMapper.buildServicesInfo(
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
    if (tasks.isEmpty) return true;
    return tasks.asMap().entries.every((entry) => _isTaskChecked(
          entry.value,
          entry.key,
        ));
  }

  List<Map<String, Object?>> _checkedTaskSnapshots() {
    final snapshots = <Map<String, Object?>>[];
    for (final entry in _tasks.asMap().entries) {
      final task = entry.value;
      if (!_isTaskChecked(task, entry.key)) continue;

      final label = task.label.trim();
      final detail = task.detail?.trim();
      if (label.isEmpty) continue;

      snapshots.add(<String, Object?>{
        'name': label,
        'label': detail == null || detail.isEmpty ? label : '$label: $detail',
        if (detail != null && detail.isNotEmpty) 'detail': detail,
        'sort': entry.key,
      });
    }
    return snapshots;
  }

  bool get _isChecklistLocked => !_uiState.isActiveWork;

  String _effectiveStatus(OrdersState state) {
    final details = state.orderDetailsUsecase?.data;
    if (details?.id == widget.order.id && details?.status != null) {
      return (details!.status ?? '').trim().toLowerCase();
    }
    return (widget.order.status ?? '').trim().toLowerCase();
  }

  bool _isWaitingFromState(OrdersState state) =>
      OrderLifecyclePolicy.isAwaitingCustomerCompletion(_effectiveStatus(state));

  bool get _canFinish => widget.order.id != null && _uiState.isActiveWork;

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
          cleaningServices:
              OrderMissionTaskMapper.buildCompletionServiceSnapshots(
            services: widget.services,
            addons: widget.addons,
          ),
          propertiesRooms: _checkedTaskSnapshots(),
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

  void _syncTimerSession({bool resetCurrentSession = false}) {
    if (!_uiState.isActiveWork) {
      _timerSession = null;
      _timerOrderId = null;
      return;
    }

    final extensionSeed =
        OrderWorkTimerHelper.latestAcceptedExtensionSeed(widget.order.timeWarnings);
    if (extensionSeed != null) {
      if (resetCurrentSession ||
          _timerSession?.sessionKey != extensionSeed.sessionKey) {
        _timerSession = OrderWorkTimerHelper.startExtensionSession(
          now: DateTime.now(),
          seed: extensionSeed,
        );
        _timerOrderId = widget.order.id;
      }
      return;
    }

    final maxDuration = OrderWorkTimerHelper.originalBookingDuration(
      assignmentHours: widget.order.myAssignment?.totalHours,
      totalHours: widget.order.totalHours,
      estimatedHours: widget.order.estimatedHours,
    );
    if (maxDuration == null) {
      _timerSession = null;
      _timerOrderId = null;
      return;
    }

    if (resetCurrentSession ||
        _timerSession == null ||
        _timerSession!.isExtension ||
        _timerOrderId != widget.order.id) {
      _timerSession = OrderWorkTimerHelper.startOriginalSession(
        now: DateTime.now(),
        maxDuration: maxDuration,
      );
      _timerOrderId = widget.order.id;
    }
  }

  void _resetExtensionSessionFromState(OrdersState state) {
    final data = state.acceptExtensionUsecase?.data;
    final minutes = data?.approvedMinutes;
    if (minutes == null || minutes <= 0) return;
    final seed = AcceptedExtensionTimerSeed(id: data?.id, minutes: minutes);
    if (_timerSession?.sessionKey == seed.sessionKey) return;
    _timerSession = OrderWorkTimerHelper.startExtensionSession(
      now: DateTime.now(),
      seed: seed,
    );
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

  String _formatClock(DateTime dateTime) {
    return DateFormat('hh:mm a', 'en').format(dateTime);
  }

  DateTime? get _orderStartTime {
    final workStarted = DateTime.tryParse(widget.order.workStartedAt ?? '');
    if (workStarted != null) return workStarted;

    final scheduled = _parseScheduledDateTime();
    if (scheduled != null) return scheduled;

    return _timerSession?.sessionStart;
  }

  DateTime? _parseScheduledDateTime() {
    final dateRaw = widget.order.scheduledDate?.trim();
    if (dateRaw == null || dateRaw.isEmpty) return null;

    final timeRaw = widget.order.scheduledTime?.trim();
    if (timeRaw == null || timeRaw.isEmpty) {
      return DateTime.tryParse(dateRaw);
    }

    final combined = DateTime.tryParse('${dateRaw}T$timeRaw');
    if (combined != null) return combined;

    final dateOnly = DateTime.tryParse(dateRaw);
    if (dateOnly == null) return null;

    final timeParts = timeRaw.split(':');
    if (timeParts.length < 2) return dateOnly;
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return dateOnly;
    return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, hour, minute);
  }

  DateTime? get _orderEndTime {
    final start = _orderStartTime;
    if (start == null) return null;

    final estimate = OrderWorkTimerHelper.originalBookingDuration(
      assignmentHours: widget.order.myAssignment?.totalHours,
      totalHours: widget.order.totalHours,
      estimatedHours: widget.order.estimatedHours,
    );
    if (estimate == null) return null;

    final extensionMinutes = OrderWorkTimerHelper.totalAcceptedExtensionMinutes(
      widget.order.timeWarnings,
    );
    return start.add(estimate + Duration(minutes: extensionMinutes));
  }

  bool get _canShowTwoTimes {
    if (!_uiState.isActiveWork || !_isWorkTimerAvailable) return false;
    return _orderStartTime != null && _orderEndTime != null;
  }

  String _serviceDate() {
    return CleaningArabicTimeFormatter.formatScheduledDate(
      widget.order.scheduledDate,
      pattern: 'yyyy/MM/dd',
    );
  }

  List<Color> get _timerGradientColors {
    if (_uiState.isWaitingCustomer) {
      return const <Color>[Color(0xff1E2A78), Color(0xff283593)];
    }
    if (_uiState.isExtensionPending || _timerSession?.isExtension == true) {
      return const <Color>[Color(0xff7C3AED), Color(0xff6D28D9)];
    }
    if (_uiState.isDispute) {
      return const <Color>[Color(0xff64748B), Color(0xff475569)];
    }
    if (_uiState.isFinal) {
      return const <Color>[Color(0xff334155), Color(0xff1F2937)];
    }
    if (_isSessionFinished) {
      return const <Color>[Color(0xffD97706), Color(0xffF59E0B)];
    }
    return const <Color>[Color(0xff1DBCC8), Color(0xff10A7B2)];
  }

  String get _missionStatusText {
    if (_uiState.isWaitingCustomer) return 'بانتظار تأكيد العميل';
    if (_uiState.isExtensionPending) return 'طلب تمديد وقت';
    if (_uiState.isDispute) return 'الطلب قيد المراجعة';
    if (_uiState == OrderDetailsUiState.completed) return 'الطلب مكتمل';
    if (_uiState == OrderDetailsUiState.cancelled) return 'الطلب ملغي';
    if (_isSessionFinished) return 'انتهى وقت الجلسة';
    return 'العمل قيد التنفيذ';
  }

  String get _timerTitleText {
    if (_uiState.isWaitingCustomer) return 'تم إرسال طلب إنهاء العمل للعميل';
    if (_uiState.isExtensionPending) return 'بانتظار ردك على طلب التمديد';
    if (_uiState.isDispute) return 'تم إيقاف إجراءات الطلب مؤقتاً';
    if (_uiState.isFinal) return 'انتهت دورة هذا الطلب';
    if (!_isWorkTimerAvailable) return 'وقت العمل غير متوفر لهذا الطلب';
    if (_isSessionFinished) return 'انتهى وقت جلسة العمل';
    return _timerSession?.isExtension == true
        ? 'الوقت المستخدم من جلسة التمديد'
        : 'الوقت المستخدم من جلسة العمل';
  }

  String get _timerValueText {
    if (_uiState.isWaitingCustomer) return 'بانتظار تأكيد العميل';
    if (_uiState.isExtensionPending) return 'بانتظار قبول أو رفض التمديد';
    if (_uiState.isDispute) return 'قيد المراجعة';
    if (_uiState == OrderDetailsUiState.completed) return 'مكتمل';
    if (_uiState == OrderDetailsUiState.cancelled) return 'ملغي';
    if (!_isWorkTimerAvailable) return '--:--:--';
    return _formatDuration(_elapsedTime);
  }

  String? get _timerHelperText {
    if (_uiState.isWaitingCustomer) {
      return 'تم قفل قائمة المهام بعد إرسال طلب الإنهاء.';
    }
    if (_uiState.isExtensionPending) {
      return 'لا يتم قبول أو رفض التمديد تلقائياً. اختر الإجراء المناسب.';
    }
    if (_uiState.isDispute) return 'يرجى انتظار توجيهات الدعم أو الإدارة.';
    if (_uiState.isFinal) return null;
    if (!_isWorkTimerAvailable) return null;
    if (_isSessionFinished) {
      return 'انتهت مدة جلسة العمل الحالية. يرجى طلب تمديد وقت إذا كنت بحاجة للمزيد.';
    }
    return null;
  }

  String get _taskListHintText {
    if (_tasks.isEmpty && _uiState.isActiveWork) {
      return 'لا توجد مهام محددة من السيرفر. يمكنك إرسال طلب الإنهاء عند اكتمال العمل.';
    }
    if (_isChecklistLocked) {
      return 'قائمة المهام مقفلة لأن الطلب ليس في مرحلة التنفيذ.';
    }
    return 'تحديد المهام التي قمت بتنفيذها';
  }

  String get _finishButtonText => 'إرسال طلب إنهاء العمل';

  _PendingExtension? get _pendingExtension {
    final warnings = widget.order.timeWarnings;
    if (warnings == null) return null;
    for (final warning in warnings.reversed) {
      final map = _asStringMap(warning);
      if (map.isEmpty) continue;
      final item = _PendingExtension.fromMap(map);
      if (item != null && item.isPending) return item;
    }
    return null;
  }

  Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key.toString(), nestedValue),
      );
    }
    return const <String, dynamic>{};
  }

  Future<void> _showRejectExtensionDialog(
    _PendingExtension extension,
  ) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض طلب التمديد'),
        content: TextField(
          controller: controller,
          maxLength: 150,
          decoration: const InputDecoration(
            hintText: 'اكتب سبب الرفض للعميل (اختياري)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('رفض التمديد'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null) return;
    widget.bloc.add(
      RejectExtensionUsecaseEvent(
        params: RejectExtensionUsecaseParams(
          id: extension.id,
          message: message,
        ),
      ),
    );
  }

  Widget _buildExtensionDecisionCard(OrdersState state) {
    if (!_uiState.isExtensionPending) return const SizedBox.shrink();
    final extension = _pendingExtension;
    final loading = state.acceptExtensionUsecaseStatus == BlocStatus.loading ||
        state.rejectExtensionUsecaseStatus == BlocStatus.loading;

    return Container(
      width: context.width,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(
            'طلب تمديد وقت',
            color: const Color(0xff6D28D9),
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          AppText.bodySmall(
            extension == null
                ? 'يوجد طلب تمديد بانتظار ردك. قم بتحديث الطلب إذا لم تظهر التفاصيل.'
                : 'طلب العميل تمديد العمل لمدة ${extension.minutes} دقيقة.',
            color: const Color(0xff475569),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: loading || extension == null
                      ? null
                      : () {
                          widget.bloc.add(
                            AcceptExtensionUsecaseEvent(
                              params: AcceptExtensionUsecaseParams(
                                id: extension.id,
                                additionalMinutes: extension.minutes,
                              ),
                            ),
                          );
                        },
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('قبول التمديد'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: loading || extension == null
                      ? null
                      : () =>
                          unawaited(_showRejectExtensionDialog(extension)),
                  child: const Text('رفض'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateNotice() {
    String? title;
    String? body;
    if (_uiState.isDispute) {
      title = 'الطلب قيد المراجعة';
      body = 'تم إيقاف إجراءات العمل مؤقتاً. يرجى انتظار الدعم أو الإدارة.';
    } else if (_uiState == OrderDetailsUiState.completed) {
      title = 'الطلب مكتمل';
      body = 'تم إغلاق دورة العمل لهذا الطلب.';
    } else if (_uiState == OrderDetailsUiState.cancelled) {
      title = 'الطلب ملغي';
      body = 'لا توجد إجراءات متاحة على هذا الطلب.';
    }
    if (title == null || body == null) return const SizedBox.shrink();
    return Container(
      width: context.width,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(title, fontWeight: FontWeight.bold),
          const SizedBox(height: 6),
          AppText.bodySmall(body, color: const Color(0xff64748B)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) =>
          (previous.completeOrderUsecaseStatus !=
                  current.completeOrderUsecaseStatus &&
              current.completeOrderUsecaseStatus == BlocStatus.success) ||
          (previous.acceptExtensionUsecaseStatus !=
                  current.acceptExtensionUsecaseStatus &&
              current.acceptExtensionUsecaseStatus == BlocStatus.success) ||
          (!_isWaitingFromState(previous) && _isWaitingFromState(current)),
      listener: (context, state) {
        if (state.acceptExtensionUsecaseStatus == BlocStatus.success) {
          _resetExtensionSessionFromState(state);
          return;
        }
        unawaited(_showWaitingConfirmationSheet());
      },
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
                      startTimeLabel:
                          _canShowTwoTimes ? 'وقت بدء العمل' : null,
                      startTimeValue: _canShowTwoTimes
                          ? _formatClock(_orderStartTime!)
                          : null,
                      endTimeLabel:
                          _canShowTwoTimes ? 'وقت الانتهاء المتوقع' : null,
                      endTimeValue: _canShowTwoTimes
                          ? _formatClock(_orderEndTime!)
                          : null,
                    ),
                    14.verticalSpace,
                    if (!_uiState.isDispute &&
                        !_uiState.isFinal &&
                        _servicesInfo.isNotEmpty) ...[
                      MissionServicesInfoCard(services: _servicesInfo),
                      14.verticalSpace,
                    ],
                    if (!_uiState.isDispute && !_uiState.isFinal)
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
                    _buildExtensionDecisionCard(widget.bloc.state),
                    _buildStateNotice(),
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
          visible: _uiState.isWaitingCustomer,
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
        final visible = _uiState.isActiveWork;
        if (!visible) return const SizedBox.shrink();
        return MissionFinishButton(
          loading: loading,
          enabled: _canFinish && !loading,
          text: _finishButtonText,
          onPressed: () => unawaited(_showCompletionMessageSheet()),
        );
      },
    );
  }
}

class _PendingExtension {
  const _PendingExtension({required this.id, required this.minutes});

  final int id;
  final int minutes;

  bool get isPending => minutes > 0;

  static _PendingExtension? fromMap(Map<String, dynamic> map) {
    final id = _asInt(_pick(map, const <String>['id', 'warningId', 'warning_id']));
    final minutes = _asInt(
      _pick(map, const <String>[
        'additionalMinutes',
        'additional_minutes',
        'requestedMinutes',
        'requested_minutes',
        'minutes',
      ]),
    );
    final workerResponse = _asString(
      _pick(map, const <String>['workerResponse', 'worker_response']),
    )?.trim().toLowerCase();
    final responseStatus = _asString(
      _pick(map, const <String>['responseStatus', 'response_status', 'status']),
    )?.trim().toLowerCase();
    if (workerResponse == 'accept' ||
        workerResponse == 'accepted' ||
        workerResponse == 'reject' ||
        workerResponse == 'rejected' ||
        responseStatus == 'accepted' ||
        responseStatus == 'rejected') {
      return null;
    }
    if (id == null || minutes == null || minutes <= 0) return null;
    return _PendingExtension(id: id, minutes: minutes);
  }
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ??
      double.tryParse(value?.toString() ?? '')?.toInt();
}
