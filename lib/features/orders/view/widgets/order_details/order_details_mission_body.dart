import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/provisional_pricing_notice.dart';
import '../../../data/models/arrive_model.dart';
import '../../../data/models/cleaning_booking_status.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/complete_order_usecase_use_case.dart';
import '../../../domain/usecases/fetch_order_details_usecase_use_case.dart';
import '../../helpers/event_assistance_order_helper.dart';
import '../../helpers/order_details_support_navigation.dart';
import '../../helpers/order_lifecycle_policy.dart';
import '../worker_payment_summary.dart';

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
  Duration _remainingTime = Duration.zero;
  Duration _overdueTime = Duration.zero;
  bool _isWorkTimerAvailable = false;
  bool _isWorkOverdue = false;
  bool _waitingSheetOpen = false;
  String? _lastCompletionMessage;
  final Map<String, bool> _taskState = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _initTasks();
    _calculateWorkTimer();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant OrderDetailsMissionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) _lastCompletionMessage = null;
    if (oldWidget.order.id != widget.order.id || oldWidget.services.length != widget.services.length || oldWidget.addons.length != widget.addons.length) {
      _initTasks();
    }
    if (oldWidget.order.id != widget.order.id || oldWidget.order.status != widget.order.status || oldWidget.order.workStartedAt != widget.order.workStartedAt || oldWidget.order.arrivedAt != widget.order.arrivedAt || oldWidget.order.totalHours != widget.order.totalHours || oldWidget.order.estimatedHours != widget.order.estimatedHours) {
      _calculateWorkTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initTasks() {
    _taskState.clear();
    for (final entry in _tasks.asMap().entries) {
      _taskState.putIfAbsent(_taskKey(entry.value, entry.key), () => false);
    }
  }

  String _taskKey(_TaskItem task, int index) => '${task.label}-$index';

  bool get _allTasksChecked {
    final tasks = _tasks;
    return tasks.isNotEmpty && tasks.asMap().entries.every((entry) => _taskState[_taskKey(entry.value, entry.key)] ?? false);
  }

  bool get _isEventAssistance => EventAssistanceOrderHelper.isEventAssistance(widget.order.propertyType);
  bool get _isChecklistLocked => _isWaitingCustomer;

  List<_TaskItem> get _tasks {
    final items = <_TaskItem>[];
    for (final service in widget.services) {
      final name = service.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(_TaskItem(label: name, detail: service.quantity == null ? null : 'x ${service.quantity}'));
    }
    for (final addon in widget.addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(_TaskItem(label: name, detail: addon.quantity == null ? null : 'x ${addon.quantity}'));
    }
    if (items.isNotEmpty) return items;
    if (_isEventAssistance) {
      final task = widget.order.propertyDetails?.customService?.trim();
      if (task != null && task.isNotEmpty) {
        final hours = EventAssistanceOrderHelper.resolveBookedHours(
          propertyHours: widget.order.propertyDetails?.hours,
          totalHours: widget.order.totalHours,
          estimatedHours: widget.order.estimatedHours,
        );
        return <_TaskItem>[_TaskItem(label: task, detail: hours == null ? null : EventAssistanceOrderHelper.formatHoursDetail(hours))];
      }
      return const <_TaskItem>[];
    }
    return const <_TaskItem>[
      _TaskItem(label: 'تنظيف غرفة النوم', detail: 'x 2'),
      _TaskItem(label: 'تنظيف الحمامات', detail: 'x 2'),
      _TaskItem(label: 'تنظيف المطبخ'),
    ];
  }

  String _effectiveStatus(OrdersState state) {
    final details = state.orderDetailsUsecase?.data;
    if (details?.id == widget.order.id && details?.status != null) return (details!.status ?? '').trim().toLowerCase();
    return (widget.order.status ?? '').trim().toLowerCase();
  }

  bool get _isWaitingCustomer => OrderLifecyclePolicy.isAwaitingCustomerCompletion(_effectiveStatus(widget.bloc.state));
  bool get _isExtensionRequested => _effectiveStatus(widget.bloc.state) == CleaningBookingStatus.timeExtensionRequested;
  bool _isWaitingFromState(OrdersState state) => OrderLifecyclePolicy.isAwaitingCustomerCompletion(_effectiveStatus(state));
  bool get _canFinish => widget.order.id != null && OrderLifecyclePolicy.canCompleteWork(_effectiveStatus(widget.bloc.state));

  String? _currentCompletionMessage(OrdersState state) {
    final value = state.completeOrderUsecase?.data?.note ?? _lastCompletionMessage;
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showCompletionMessageSheet() async {
    if (!_canFinish || widget.order.id == null) return;
    final controller = TextEditingController(text: _lastCompletionMessage ?? '');
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppText.titleMedium('إرسال طلب تأكيد الإنهاء', fontWeight: FontWeight.bold, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          AppText.bodyMedium('يمكنك كتابة ملاحظة للعميل قبل إرسال طلب تأكيد إنهاء الخدمة.', textAlign: TextAlign.center, color: const Color(0xff6B7280)),
          const SizedBox(height: 14),
          TextField(controller: controller, maxLines: 4, maxLength: 1000, textInputAction: TextInputAction.newline, decoration: InputDecoration(hintText: 'مثال: تم إنهاء الخدمة بالكامل.', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text), style: FilledButton.styleFrom(backgroundColor: const Color(0xff1DBCC8), foregroundColor: Colors.white), child: const Text('إرسال للعميل'))),
          ]),
        ]),
      ),
    );
    controller.dispose();
    if (message == null || widget.order.id == null) return;
    final trimmed = message.trim();
    setState(() => _lastCompletionMessage = trimmed.isEmpty ? null : trimmed);
    widget.bloc.add(CompleteOrderUsecaseEvent(params: CompleteOrderUsecaseParams(id: widget.order.id!, completionMessage: trimmed)));
  }

  Future<void> _showWaitingConfirmationSheet() async {
    if (!mounted || _waitingSheetOpen) return;
    _waitingSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_outlined, size: 66, color: Color(0xff21B8C5)),
          const SizedBox(height: 12),
          AppText.titleMedium('تم إرسال طلب التأكيد', fontWeight: FontWeight.bold, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          AppText.bodyMedium('تم إرسال طلب إنهاء الخدمة إلى العميل. سيتم تحديث حالة الطلب عند قبول العميل أو طلب إجراء آخر.', textAlign: TextAlign.center, color: const Color(0xff6B7280)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: widget.order.id == null ? null : () { Navigator.of(ctx).pop(); widget.bloc.add(FetchOrderDetailsUsecaseEvent(params: FetchOrderDetailsUsecaseParams(id: widget.order.id!))); }, child: const Text('تحديث الحالة'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () => Navigator.of(ctx).pop(), style: FilledButton.styleFrom(backgroundColor: const Color(0xff1E2A78), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: AppText.labelLarge('تم', color: Colors.white))),
          ]),
        ]),
      ),
    );
    _waitingSheetOpen = false;
  }

  DateTime? _parseDate(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Duration? _durationFromHours(double? hours) => hours == null || hours <= 0 ? null : Duration(minutes: (hours * 60).round());

  bool _isActiveWorkTimerStatus(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    return normalized == CleaningBookingStatus.inProgress || normalized == CleaningBookingStatus.timeExtensionRequested;
  }

  DateTime? _resolveExpectedFinishAt(String status) {
    if (!_isActiveWorkTimerStatus(status)) return null;
    final startAt = _parseDate(widget.order.workStartedAt) ?? _parseDate(widget.order.arrivedAt);
    final duration = _durationFromHours((widget.order.totalHours != null && widget.order.totalHours! > 0) ? widget.order.totalHours : widget.order.estimatedHours);
    if (startAt == null || duration == null) return null;
    return startAt.add(duration);
  }

  void _setTimerUnavailable() {
    if (!mounted) return;
    setState(() { _isWorkTimerAvailable = false; _isWorkOverdue = false; _remainingTime = Duration.zero; _overdueTime = Duration.zero; });
  }

  void _calculateWorkTimer() {
    final status = _effectiveStatus(widget.bloc.state);
    if (!_isActiveWorkTimerStatus(status)) { _setTimerUnavailable(); return; }
    final expectedFinishAt = _resolveExpectedFinishAt(status);
    if (expectedFinishAt == null) { _setTimerUnavailable(); return; }
    final diff = expectedFinishAt.difference(DateTime.now());
    final isOverdue = diff.isNegative;
    if (!mounted) return;
    setState(() { _isWorkTimerAvailable = true; _isWorkOverdue = isOverdue; _remainingTime = isOverdue ? Duration.zero : diff; _overdueTime = isOverdue ? diff.abs() : Duration.zero; });
  }

  void _startTimer() { _timer?.cancel(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateWorkTimer()); }

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
    if (_isWaitingCustomer) return const <Color>[Color(0xff1E2A78), Color(0xff283593)];
    if (_isExtensionRequested) return const <Color>[Color(0xff7C3AED), Color(0xff6D28D9)];
    if (_isWorkOverdue) return const <Color>[Color(0xffD97706), Color(0xffF59E0B)];
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
    if (_isWorkOverdue) return 'يرجى إنهاء العمل وإرسال طلب التأكيد للعميل عند الانتهاء.';
    return null;
  }

  String get _taskListHintText => _isChecklistLocked ? 'قائمة المهام مقفلة لأن طلب إنهاء العمل قد تم إرساله.' : 'تحديد المهام التي قمت بتنفيذها';
  String get _finishButtonText => _isWaitingCustomer ? 'تم إرسال طلب الإنهاء' : 'إنهاء العمل';

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) => (previous.completeOrderUsecaseStatus != current.completeOrderUsecaseStatus && current.completeOrderUsecaseStatus == BlocStatus.success) || (!_isWaitingFromState(previous) && _isWaitingFromState(current)),
      listener: (context, state) => unawaited(_showWaitingConfirmationSheet()),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 14.w),
        child: Column(children: [
          Row(children: [IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)), Expanded(child: AppText.headlineMedium('تفاصيل الطلب ${widget.order.bookingNumber ?? ''}', textAlign: TextAlign.center)), const SizedBox(width: 48)]),
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildTimerCard(),
            14.verticalSpace,
            _buildTaskCard(context),
            14.verticalSpace,
            _buildPaymentSummary(),
            _buildWaitingCustomerCard(),
            14.verticalSpace,
            _buildFinishButton(),
            10.verticalSpace,
            _buildSupportButton(context),
            20.verticalSpace,
          ]))),
        ]),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: _timerGradientColors)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [AppText.labelLarge(_serviceDate(), color: Colors.white), AppText.labelLarge(_missionStatusText, color: Colors.white, fontWeight: FontWeight.bold)]),
        10.verticalSpace,
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.white.withAlpha(32), borderRadius: BorderRadius.circular(12)), child: Column(children: [
          AppText.bodyMedium(_timerTitleText, color: Colors.white, textAlign: TextAlign.center),
          4.verticalSpace,
          AppText.bodyLarge(_timerValueText, color: Colors.white, fontWeight: FontWeight.bold, textAlign: TextAlign.center),
          if (_timerHelperText != null) ...[6.verticalSpace, AppText.bodySmall(_timerHelperText!, color: Colors.white, textAlign: TextAlign.center)],
        ])),
      ]),
    );
  }

  Widget _buildTaskCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xffECEFF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppText.titleMedium('قائمة المهام', color: const Color(0xff19B7C3), fontWeight: FontWeight.bold),
        4.verticalSpace,
        AppText.bodySmall(_taskListHintText, color: _isChecklistLocked ? const Color(0xffB45309) : const Color(0xff6B7280)),
        12.verticalSpace,
        ..._tasks.asMap().entries.map((entry) {
          final task = entry.value;
          final taskKey = _taskKey(task, entry.key);
          final checked = _isChecklistLocked || (_taskState[taskKey] ?? false);
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: _isChecklistLocked ? const Color(0xffF1F5F9) : const Color(0xffF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: _isChecklistLocked ? const Color(0xffCBD5E1) : const Color(0xffE5E7EB))), child: Row(children: [
            Checkbox(value: checked, onChanged: _isChecklistLocked ? null : (value) => setState(() => _taskState[taskKey] = value ?? false), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), side: const BorderSide(color: Color(0xffCBD5E1))),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AppText.bodyMedium(task.label, fontWeight: FontWeight.w700, color: _isChecklistLocked ? const Color(0xff64748B) : null), if (task.detail != null) AppText.bodySmall(task.detail!, color: const Color(0xff9CA3AF))])),
          ])));
        }),
        if (!_isChecklistLocked && !_allTasksChecked) ...[2.verticalSpace, AppText.bodySmall('يرجى تحديد جميع المهام قبل إنهاء العمل', color: context.error)],
      ]),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppText.titleSmall('ملخص الدفع', fontWeight: FontWeight.w700),
        10.verticalSpace,
        WorkerPaymentSummary(basePrice: widget.order.basePrice, travelFee: widget.order.myAssignment?.travelFee ?? widget.order.travelFee, addonsTotal: widget.order.addonsTotal, totalPrice: widget.order.totalPrice, showAddonsTotal: false, useWorkerShare: widget.order.myAssignment != null, serviceShareAmount: widget.order.myAssignment?.serviceShareAmount, workerAmount: widget.order.myAssignment?.workerAmount, adminMargin: widget.order.adminMargin),
        if (widget.order.isPricingFinal == false) ...[10.verticalSpace, const ProvisionalPricingNotice()],
        10.verticalSpace,
        Row(children: [const Icon(Icons.payments_outlined, color: Color(0xff22C55E), size: 18), 6.horizontalSpace, AppText.bodySmall('نقدا عند الاستلام')]),
      ]),
    );
  }

  Widget _buildWaitingCustomerCard() {
    return BlocBuilder<OrdersBloc, OrdersState>(bloc: widget.bloc, builder: (context, state) {
      final completionMessage = _currentCompletionMessage(state);
      if (!_isWaitingCustomer) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        12.verticalSpace,
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xffEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffCBD5E1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.hourglass_top_rounded, color: Color(0xff1E2A78)), 8.horizontalSpace, Expanded(child: AppText.bodyMedium('تم إرسال طلب إنهاء العمل إلى العميل. بانتظار التأكيد أو طلب إجراء آخر.', color: const Color(0xff1E2A78), textAlign: TextAlign.start))]),
          if (completionMessage != null) ...[10.verticalSpace, AppText.labelMedium('رسالتك للعميل:', color: const Color(0xff1E2A78), fontWeight: FontWeight.w700), 4.verticalSpace, AppText.bodySmall(completionMessage, color: const Color(0xff374151), textAlign: TextAlign.start)],
        ])),
      ]);
    });
  }

  Widget _buildFinishButton() {
    return BlocBuilder<OrdersBloc, OrdersState>(bloc: widget.bloc, builder: (context, state) {
      final loading = state.completeOrderUsecaseStatus == BlocStatus.loading;
      final canSendFinishRequest = !_isChecklistLocked && _canFinish && _allTasksChecked && !loading;
      return FilledButton(onPressed: !canSendFinishRequest ? null : () => unawaited(_showCompletionMessageSheet()), style: FilledButton.styleFrom(backgroundColor: const Color(0xff1DBCC8), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : AppText.labelLarge(_finishButtonText, color: Colors.white, fontWeight: FontWeight.w700));
    });
  }

  Widget _buildSupportButton(BuildContext context) {
    return FilledButton(
      onPressed: widget.order.id == null ? null : () => openOrderUrgentSupport(context, widget.order.id!),
      style: FilledButton.styleFrom(backgroundColor: context.error, foregroundColor: context.onError, padding: const EdgeInsets.symmetric(vertical: 14)),
      child: AppText.labelLarge('طلب دعم عاجل', color: context.onError, fontWeight: FontWeight.bold),
    );
  }
}

class _TaskItem {
  const _TaskItem({required this.label, this.detail});
  final String label;
  final String? detail;
}
