import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';

import '../../../data/models/arrive_model.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/complete_order_usecase_use_case.dart';
import '../../helpers/order_lifecycle_policy.dart';

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
  bool _waitingSheetOpen = false;
  final Map<String, bool> _taskState = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
    _initTasks();
  }

  @override
  void didUpdateWidget(covariant OrderDetailsMissionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.services.length != widget.services.length ||
        oldWidget.addons.length != widget.addons.length) {
      _initTasks();
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
    return tasks.isNotEmpty &&
        tasks.asMap().entries.every(
          (entry) => _taskState[_taskKey(entry.value, entry.key)] ?? false,
        );
  }

  List<_TaskItem> get _tasks {
    final items = <_TaskItem>[];
    for (final service in widget.services) {
      final name = service.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(
        _TaskItem(
          label: name,
          detail: service.quantity == null ? null : 'x ${service.quantity}',
        ),
      );
    }
    for (final addon in widget.addons) {
      final name = addon.name?.trim();
      if (name == null || name.isEmpty) continue;
      items.add(
        _TaskItem(
          label: name,
          detail: addon.quantity == null ? null : 'x ${addon.quantity}',
        ),
      );
    }
    if (items.isNotEmpty) {
      return items;
    }
    return const <_TaskItem>[
      _TaskItem(label: 'تنظيف غرفة النوم', detail: 'x 2'),
      _TaskItem(label: 'تنظيف الحمامات', detail: 'x 2'),
      _TaskItem(label: 'تنظيف المطبخ'),
    ];
  }

  String _effectiveStatus(OrdersState state) {
    final details = state.orderDetailsUsecase?.data;
    if (details?.id == widget.order.id && details?.status != null) {
      return (details!.status ?? '').toLowerCase();
    }
    return (widget.order.status ?? '').toLowerCase();
  }

  bool get _isWaitingCustomer =>
      OrderLifecyclePolicy.isAwaitingCustomerCompletion(
        _effectiveStatus(widget.bloc.state),
      );

  bool _isWaitingFromState(OrdersState state) =>
      OrderLifecyclePolicy.isAwaitingCustomerCompletion(
        _effectiveStatus(state),
      );

  bool get _canFinish =>
      widget.order.id != null &&
      OrderLifecyclePolicy.canCompleteWork(_effectiveStatus(widget.bloc.state));

  Future<void> _showWaitingConfirmationSheet() async {
    if (!mounted || _waitingSheetOpen) return;
    _waitingSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 66,
                color: Color(0xff21B8C5),
              ),
              const SizedBox(height: 12),
              AppText.titleMedium(
                'تم إنهاء المهمة',
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              AppText.bodyMedium(
                'يرجى انتظار تأكيد العميل على إنهاء الخدمة.',
                textAlign: TextAlign.center,
                color: const Color(0xff6B7280),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: context.width,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff1E2A78),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: AppText.labelLarge('تم', color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
    _waitingSheetOpen = false;
  }

  void _calculateRemainingTime() {
    final arrived = widget.order.arrivedAt;
    if (arrived == null) {
      if (mounted) {
        setState(() => _remainingTime = Duration.zero);
      }
      return;
    }
    final arrivedAt = DateTime.tryParse(arrived);
    if (arrivedAt == null) {
      if (mounted) {
        setState(() => _remainingTime = Duration.zero);
      }
      return;
    }
    final estimatedHours = widget.order.estimatedHours ?? 0;
    final estimatedDuration = Duration(
      hours: estimatedHours.floor(),
      minutes: ((estimatedHours - estimatedHours.floor()) * 60).round(),
    );
    final endTime = arrivedAt.add(estimatedDuration);
    final diff = endTime.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      _remainingTime = diff.isNegative ? Duration.zero : diff;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
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
    return DateFormat('yyyy_MM_dd', 'en').format(date);
  }

  Widget _summaryRow(String title, String value, {bool total = false}) {
    final color = total ? const Color(0xff111827) : const Color(0xff374151);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bodyMedium(
          title,
          color: color,
          fontWeight: total ? FontWeight.w700 : FontWeight.w500,
        ),
        AppText.bodyMedium(
          value,
          color: color,
          fontWeight: total ? FontWeight.w700 : FontWeight.w500,
        ),
      ],
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
          (!_isWaitingFromState(previous) && _isWaitingFromState(current)),
      listener: (context, state) {
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xff1DBCC8), Color(0xff10A7B2)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.labelLarge(
                                _serviceDate(),
                                color: Colors.white,
                              ),
                              AppText.labelLarge(
                                'العمل قيد التنفيذ',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          10.verticalSpace,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(32),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                AppText.bodyMedium(
                                  _isWaitingCustomer
                                      ? 'بانتظار تأكيد العميل على إنهاء العمل'
                                      : 'الوقت المتبقي لإنهاء العمل',
                                  color: Colors.white,
                                ),
                                4.verticalSpace,
                                AppText.bodyLarge(
                                  _formatDuration(_remainingTime),
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    14.verticalSpace,
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xffECEFF3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleMedium(
                            'قائمة المهام',
                            color: const Color(0xff19B7C3),
                            fontWeight: FontWeight.bold,
                          ),
                          4.verticalSpace,
                          AppText.bodySmall(
                            'تحديد المهام التي قمت بتنفيذها',
                            color: const Color(0xff6B7280),
                          ),
                          12.verticalSpace,
                          ..._tasks.asMap().entries.map((entry) {
                            final task = entry.value;
                            final taskKey = _taskKey(task, entry.key);
                            final checked = _taskState[taskKey] ?? false;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xffE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: checked,
                                      onChanged: (value) {
                                        setState(() {
                                          _taskState[taskKey] = value ?? false;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xffCBD5E1),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText.bodyMedium(
                                            task.label,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          if (task.detail != null)
                                            AppText.bodySmall(
                                              task.detail!,
                                              color: const Color(0xff9CA3AF),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          if (!_allTasksChecked && !_isWaitingCustomer) ...[
                            2.verticalSpace,
                            AppText.bodySmall(
                              'يرجى تحديد جميع المهام قبل إنهاء العمل',
                              color: context.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                    14.verticalSpace,
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleSmall(
                            'ملخص الدفع',
                            fontWeight: FontWeight.w700,
                          ),
                          10.verticalSpace,
                          _summaryRow(
                            'تكلفة الخدمة',
                            '${widget.order.basePrice ?? 0} ل.س',
                          ),
                          6.verticalSpace,
                          _summaryRow(
                            'رسوم التنقل',
                            '${widget.order.travelFee ?? 0} ل.س',
                          ),
                          if ((widget.order.addonsTotal ?? 0) > 0) ...[
                            6.verticalSpace,
                            _summaryRow(
                              'الرسوم الإضافية',
                              '${widget.order.addonsTotal ?? 0} ل.س',
                            ),
                          ],
                          10.verticalSpace,
                          const Divider(),
                          10.verticalSpace,
                          _summaryRow(
                            'الإجمالي',
                            '${widget.order.totalPrice ?? 0} ل.س',
                            total: true,
                          ),
                          10.verticalSpace,
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: Color(0xff22C55E),
                                size: 18,
                              ),
                              6.horizontalSpace,
                              AppText.bodySmall('نقدا عند الاستلام'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isWaitingCustomer) ...[
                      12.verticalSpace,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              color: Color(0xff1E2A78),
                            ),
                            8.horizontalSpace,
                            Expanded(
                              child: AppText.bodyMedium(
                                'تم إنهاء الخدمة. بانتظار تأكيد العميل.',
                                color: const Color(0xff1E2A78),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    14.verticalSpace,
                    BlocBuilder<OrdersBloc, OrdersState>(
                      bloc: widget.bloc,
                      builder: (context, state) {
                        final loading =
                            state.completeOrderUsecaseStatus ==
                            BlocStatus.loading;
                        final canSendFinishRequest =
                            _canFinish && _allTasksChecked && !loading;
                        return FilledButton(
                          onPressed: !canSendFinishRequest
                              ? null
                              : () {
                                  widget.bloc.add(
                                    CompleteOrderUsecaseEvent(
                                      params: CompleteOrderUsecaseParams(
                                        id: widget.order.id!,
                                      ),
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff1DBCC8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : AppText.labelLarge(
                                  _isWaitingCustomer
                                      ? 'بانتظار تأكيد العميل'
                                      : 'إنهاء العمل',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                        );
                      },
                    ),
                    10.verticalSpace,
                    FilledButton(
                      onPressed: () => context.pushRoute('/emergencysos'),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.error,
                        foregroundColor: context.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: AppText.labelLarge(
                        'SOS',
                        color: context.onError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
}

class _TaskItem {
  const _TaskItem({required this.label, this.detail});

  final String label;
  final String? detail;
}
