import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/location/worker_location_tracker.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/worker_session_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_worker_order_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../estate_info_card.dart';
import 'worker_order_overview_card.dart';
import 'worker_travel_contact_card.dart';
import 'worker_order_requirements_card.dart';
import '../../../../../core/theme/worker_app_colors.dart';
import '../worker_action_terms_sheet.dart';

class MultiDayOrderDetailsBody extends StatefulWidget {
  const MultiDayOrderDetailsBody({
    super.key,
    required this.order,
    required this.initialSchedule,
    this.initialSelectedSessionId,
    this.onScheduleChanged,
    this.sessionDetailsOnly = false,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final WorkerBookingScheduleModel initialSchedule;
  final int? initialSelectedSessionId;
  final ValueChanged<WorkerBookingScheduleModel>? onScheduleChanged;
  final bool sessionDetailsOnly;

  @override
  State<MultiDayOrderDetailsBody> createState() =>
      _MultiDayOrderDetailsBodyState();
}

class _MultiDayOrderDetailsBodyState extends State<MultiDayOrderDetailsBody> {
  late WorkerBookingScheduleModel _schedule;
  int? _selectedSessionId;
  bool _busy = false;
  String? _error;
  WorkerSessionSecurityCodeModel? _securityCode;
  Timer? _timer;
  Timer? _statusRefreshTimer;
  bool _refreshing = false;
  DateTime _now = DateTime.now();

  int? get _bookingId => widget.order.id;

  WorkerBookingSessionModel? get _activeSession {
    final selected = _schedule.sessionById(_selectedSessionId);
    if (selected != null) return selected;
    final next = _schedule.nextSession;
    if (next != null) return _schedule.sessionById(next.id) ?? next;
    return _schedule.sessions.isEmpty ? null : _schedule.sessions.first;
  }

  @override
  void initState() {
    super.initState();
    _schedule = widget.initialSchedule;
    _selectedSessionId = _resolveInitialSessionId();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _busy || _refreshing) return;
      final session = _activeSession;
      if (session?.isAwaitingStartVerification == true ||
          session?.isAwaitingCustomerCompletion == true) {
        unawaited(_refresh());
      }
    });
  }

  @override
  void didUpdateWidget(covariant MultiDayOrderDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSchedule != widget.initialSchedule) {
      final shouldStopTracking = _trackedSessionWasRemoved(
        widget.initialSchedule,
      );
      _applySchedule(widget.initialSchedule);
      if (shouldStopTracking) {
        unawaited(WorkerLocationTracker.instance.stop());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  int? _resolveInitialSessionId() {
    final requested = widget.initialSelectedSessionId;
    if (_schedule.sessionById(requested) != null) return requested;
    final nextId = _schedule.nextSession?.id;
    if (_schedule.sessionById(nextId) != null) return nextId;
    for (final session in _schedule.sessions) {
      if (!session.isTerminal && session.id != null) return session.id;
    }
    return _schedule.sessions.isEmpty ? null : _schedule.sessions.last.id;
  }

  bool _trackedSessionWasRemoved(WorkerBookingScheduleModel schedule) {
    final tracker = WorkerLocationTracker.instance;
    final trackedSessionId = tracker.activeSessionId;

    return tracker.activeBookingId == _bookingId &&
        trackedSessionId != null &&
        schedule.sessionById(trackedSessionId) == null;
  }

  void _applySchedule(WorkerBookingScheduleModel schedule) {
    final selectedRemoved =
        _selectedSessionId != null &&
        schedule.sessionById(_selectedSessionId) == null;
    final securityCodeSessionId = _securityCode?.sessionId;
    final securityCodeSession = securityCodeSessionId == null
        ? null
        : schedule.sessionById(securityCodeSessionId);
    final securityCodeRemoved =
        securityCodeSessionId != null && securityCodeSession == null;
    final securityCodeExpiresAt = DateTime.tryParse(
      _securityCode?.expiresAt ?? '',
    )?.toLocal();
    final securityCodeExpired =
        securityCodeExpiresAt != null &&
        !securityCodeExpiresAt.isAfter(DateTime.now());
    final securityCodeNoLongerAwaitingVerification =
        securityCodeSessionId != null &&
        securityCodeSession?.isAwaitingStartVerification != true;

    _schedule = schedule;

    if (schedule.sessions.isEmpty) {
      _selectedSessionId = null;
    } else if (selectedRemoved || _selectedSessionId == null) {
      _selectedSessionId = _resolveInitialSessionId();
    }

    if (selectedRemoved ||
        securityCodeRemoved ||
        securityCodeExpired ||
        securityCodeNoLongerAwaitingVerification ||
        schedule.sessions.isEmpty) {
      _securityCode = null;
    }
  }

  Future<void> _refresh() async {
    final bookingId = _bookingId;
    if (bookingId == null || _refreshing) return;
    _refreshing = true;
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .fetchBookingSchedule(bookingId);
      final schedule = result.schedule;
      if (!mounted || schedule == null) return;

      final shouldStopTracking = _trackedSessionWasRemoved(schedule);
      if (shouldStopTracking) {
        await WorkerLocationTracker.instance.stop();
        if (!mounted) return;
      }

      setState(() {
        _applySchedule(schedule);
        _error = null;
      });
      widget.onScheduleChanged?.call(schedule);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحديث حالة زيارات المناسبة.');
    } finally {
      _refreshing = false;
    }
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    if (_busy || !mounted) return false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
      return mounted;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _error = _friendlyError(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSessionDetailsAfterAction(int sessionId) async {
    if (!mounted || widget.sessionDetailsOnly) return;
    final refreshedSession = _schedule.sessionById(sessionId);
    if (refreshedSession == null) return;
    await _openSessionDetails(refreshedSession);
  }

  String? _sessionDateValue(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  FetchOrdersUsecaseModelDataItem _orderForSession(
    WorkerBookingSessionModel session,
  ) {
    final json = Map<String, dynamic>.from(widget.order.toJson());
    final assignment = session.workerAssignmentState;
    final serviceShare =
        assignment?.serviceShareAmount ??
        session.financial?.baseAmount ??
        session.pricing?.basePrice;
    final travelFee =
        assignment?.travelFee ??
        session.financial?.travelAmount ??
        session.pricing?.travelFee;
    final adminMargin =
        assignment?.adminMarginAmount ?? session.pricing?.adminMargin;
    final workerAmount =
        assignment?.workerAmount ??
        assignment?.netAmount ??
        session.financial?.netAmount;
    final grossAmount =
        assignment?.grossAmount ??
        session.financial?.grossAmount ??
        ((serviceShare ?? 0) + (travelFee ?? 0));

    json
      ..['status'] = session.status
      ..['statusLabel'] = session.statusLabel
      ..['worker_order_status'] = assignment?.status ?? session.status
      ..['workerOrderStatus'] = assignment?.status ?? session.status
      ..['scheduledDate'] = _sessionDateValue(session.date)
      ..['scheduledTime'] = session.time
      ..['estimatedHours'] = session.hours
      ..['totalHours'] = assignment?.totalHours ?? session.hours
      ..['bookingTotalHours'] = session.hours
      ..['basePrice'] = serviceShare ?? session.pricing?.basePrice
      ..['addonsTotal'] = 0
      ..['travelFee'] = travelFee
      ..['travelDistanceKm'] = session.pricing?.travelDistanceKm
      ..['adminMargin'] = adminMargin
      ..['totalPrice'] = grossAmount
      ..['bookingTotalPrice'] = grossAmount
      ..['isPricingFinal'] = session.pricing?.isPricingFinal ?? true
      ..['startedTravelAt'] =
          assignment?.startedTravelAt ?? session.startedTravelAt
      ..['arrivedAt'] = assignment?.arrivedAt ?? session.arrivedAt
      ..['workStartedAt'] = assignment?.workStartedAt ?? session.workStartedAt
      ..['workFinishedAt'] =
          assignment?.workFinishedAt ?? session.workFinishedAt
      ..['customerConfirmedAt'] = session.customerConfirmedAt
      ..['cancelledAt'] = session.cancelledAt
      ..['cancellationReason'] = session.cancellationReason
      ..['openTime'] = session.isOpenTime
          ? widget.order.toJson()['openTime']
          : null;

    if (assignment != null) {
      json['myAssignment'] = <String, dynamic>{
        'id': assignment.id,
        'workerId': assignment.workerId,
        'status': assignment.status,
        'startedTravelAt': assignment.startedTravelAt,
        'arrivedAt': assignment.arrivedAt,
        'startApprovedAt': assignment.startApprovedAt,
        'workStartedAt': assignment.workStartedAt,
        'workFinishedAt': assignment.workFinishedAt,
        'totalHours': assignment.totalHours ?? session.hours,
        'serviceShareAmount': serviceShare,
        'travelFee': travelFee,
        'adminMarginAmount': adminMargin,
        'workerAmount': workerAmount,
        'currency':
            assignment.currency ??
            session.financial?.currency ??
            session.pricing?.currency ??
            widget.order.currency,
      };
    }

    return FetchOrdersUsecaseModelDataItem.fromJson(json);
  }

  Widget _buildSessionOrderDetails(WorkerBookingSessionModel session) {
    final order = _orderForSession(session);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.headlineMedium(
                      'تفاصيل الزيارة',
                      textAlign: TextAlign.start,
                    ),
                    AppText.bodySmall(
                      'رقم الطلب: ${order.bookingNumber ?? widget.order.bookingNumber ?? '—'}',
                      color: const Color(0xff6B7280),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xffB91C1C)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_busy) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 12),
                ],
                WorkerOrderOverviewCard(order: order, visit: session),
                const SizedBox(height: 14),
                EstateInfoCard(order: order),
                const SizedBox(height: 14),
                _sessionOrderContextCard(session),
                const SizedBox(height: 14),
                if (_shouldShowNavigationMap(session)) ...[
                  _travelContactCard(),
                  const SizedBox(height: 12),
                  _SessionNavigationMapCard(order: order),
                ],
                const SizedBox(height: 14),
                _sessionCard(session),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('overlap') || text.contains('conflict')) {
      return 'تعذر تنفيذ العملية بسبب تعارض في الجدول.';
    }
    return 'تعذر تنفيذ العملية. حدّث الزيارة وتحقق من الصلاحيات ثم حاول مرة أخرى.';
  }

  Future<void> _startTravel() async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !OrderLifecyclePolicy.canStartTravelForSession(session)) {
      return;
    }
    if (!OrderLifecyclePolicy.isSessionStartTravelWithinAllowedWindow(
      session,
    )) {
      AppToast.showErrorGlobal(
        OrderLifecyclePolicy.startTravelUnavailableMessage,
      );
      return;
    }
    final succeeded = await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().startTravel(
        bookingId: bookingId,
        sessionId: sessionId,
      );
      await WorkerLocationTracker.instance.start(
        bookingId,
        sessionId: sessionId,
      );
    });
    if (succeeded) {
      await _openSessionDetailsAfterAction(sessionId);
    }
  }

  Future<void> _openSessionDetails(WorkerBookingSessionModel session) async {
    final sessionId = session.id;
    if (sessionId == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: MultiDayOrderDetailsBody(
              order: widget.order,
              initialSchedule: _schedule,
              initialSelectedSessionId: sessionId,
              onScheduleChanged: widget.onScheduleChanged,
              sessionDetailsOnly: true,
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _arrive() async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !session.canArrive) {
      return;
    }
    final succeeded = await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().arrive(
        bookingId: bookingId,
        sessionId: sessionId,
      );
      await WorkerLocationTracker.instance.stop();
    });
    if (succeeded) {
      await _openSessionDetailsAfterAction(sessionId);
    }
  }

  Future<void> _fetchSecurityCode() async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !session.isAwaitingStartVerification ||
        _busy) {
      return;
    }
    if (!widget.sessionDetailsOnly) {
      await _openSessionDetails(session);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .fetchSecurityCode(bookingId: bookingId, sessionId: sessionId);
      if (!mounted) return;
      setState(() => _securityCode = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startWork() async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !session.canStartWork) {
      return;
    }
    final succeeded = await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().startWork(
        bookingId: bookingId,
        sessionId: sessionId,
      );
      await WorkerLocationTracker.instance.stop();
    });
    if (succeeded) {
      await _openSessionDetailsAfterAction(sessionId);
    }
  }

  Future<void> _complete() async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !session.canComplete) {
      return;
    }

    final message = await _askText(
      title: 'إنهاء عمل هذه الزيارة',
      hint: 'رسالة الإكمال للعميل (اختياري)',
      isRequired: false,
      maxLength: 1000,
    );
    if (message == null) return;

    final succeeded = await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().complete(
        bookingId: bookingId,
        sessionId: sessionId,
        completionMessage: message,
      );
    });
    if (succeeded) {
      await _openSessionDetailsAfterAction(sessionId);
    }
  }

  Future<void> _decideOpenTimeExtension(String decision) async {
    final session = _activeSession;
    final extensionId = session?.openTime?.pendingExtension?.id;
    if (session == null || extensionId == null) return;
    String? reason;
    if (decision == 'rejected') {
      reason = await _askText(
        title: 'رفض تمديد الزيارة',
        hint: 'سبب الرفض',
        isRequired: true,
        maxLength: 2000,
      );
      if (reason == null || reason.trim().isEmpty) return;
    }

    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().decideOpenTimeExtension(
        extensionId: extensionId,
        decision: decision,
        reason: reason,
      );
    });
  }

  Future<void> _decideOpenTimeEnd(String decision) async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null || sessionId == null) return;
    String? reason;
    if (decision == 'rejected') {
      reason = await _askText(
        title: 'رفض إنهاء الزيارة',
        hint: 'سبب الرفض',
        isRequired: true,
        maxLength: 2000,
      );
      if (reason == null || reason.trim().isEmpty) return;
    }

    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().decideOpenTimeEnd(
        bookingId: bookingId,
        sessionId: sessionId,
        decision: decision,
        reason: reason,
      );
    });
  }

  Future<void> _cancelSession() async {
    if (!await confirmWorkerActionTerms(
      context,
      cancelling: true,
      cancellationPenaltyAmount: widget.order.workerCancellationPenaltyAmount,
    )) {
      return;
    }
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !session.canCancel) {
      return;
    }

    final reason = await _askText(
      title: 'إلغاء الزيارة',
      hint: 'سبب الإلغاء',
      isRequired: true,
      maxLength: 1000,
    );
    if (reason == null || reason.trim().isEmpty) return;

    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().cancel(
        bookingId: bookingId,
        sessionId: sessionId,
        reason: reason,
      );
      await WorkerLocationTracker.instance.stop();
    });
  }

  Future<void> _sendSos() async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !OrderLifecyclePolicy.canShowSessionSos(session)) {
      return;
    }

    final message = await _askText(
      title: 'إرسال SOS للزيارة ${session.sequence}',
      hint: 'اشرح الحالة الطارئة',
      isRequired: true,
      maxLength: 1000,
    );
    if (message == null || message.trim().isEmpty) return;

    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().sendSos(
        bookingId: bookingId,
        sessionId: sessionId,
        data: <String, dynamic>{
          'emergency_type': 'safety_threat',
          'message': message.trim(),
        },
      );
    });
  }

  Future<String?> _askText({
    required String title,
    required String hint,
    required bool isRequired,
    int? maxLength,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 5,
            maxLength: maxLength,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (isRequired && value.isEmpty) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  String _dateApi(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _dateLabel(WorkerBookingSessionModel session) {
    return CleaningArabicTimeFormatter.formatScheduledDate(
      _dateApi(session.date),
      includeWeekday: true,
    );
  }

  String _timeLabel(String? time) =>
      CleaningArabicTimeFormatter.formatFromScheduledTimeField(time);

  String _hours(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  String _money(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  String _statusLabel(WorkerBookingSessionModel session) {
    final fromApi = session.statusLabel?.trim();
    if (fromApi != null && fromApi.isNotEmpty) {
      final translated = arabicCleaningStatusLabel(fromApi, fallback: '');
      if (translated.isNotEmpty) return translated;
    }
    return switch (session.status) {
      'scheduled' => 'مجدول',
      'worker_assigned' =>
        session.startedTravelAt != null
            ? 'في الطريق إلى العميل'
            : 'جاهز للتنفيذ',
      'awaiting_start_verification' => 'بانتظار تحقق العميل',
      'awaiting_worker_start_confirmation' => 'بانتظار بدء العمال',
      'in_progress' => 'قيد التنفيذ',
      'awaiting_customer_completion' => 'بانتظار تأكيد العميل',
      'time_extension_requested' => 'طلب تمديد وقت',
      'completed' => 'مكتمل',
      'cancelled' => 'ملغي',
      'under_dispute' => 'قيد المراجعة',
      _ => 'قيد المعالجة',
    };
  }

  Duration? _remaining(WorkerBookingSessionModel session) {
    final openTimeCeiling = DateTime.tryParse(
      session.openTime?.ceilingEndsAt ?? '',
    );
    if (openTimeCeiling != null) {
      final remaining = openTimeCeiling.difference(_now);
      return remaining.isNegative ? Duration.zero : remaining;
    }
    final started = DateTime.tryParse(session.workStartedAt ?? '');
    if (started == null || session.hours <= 0) return null;
    final end = started.add(Duration(minutes: (session.hours * 60).round()));
    final remaining = end.difference(_now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _durationLabel(Duration value) {
    final h = value.inHours.toString().padLeft(2, '0');
    final m = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _sessionSelector() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _schedule.sessions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final session = _schedule.sessions[index];
          return ChoiceChip(
            selected: session.id == _selectedSessionId,
            onSelected: (_) {
              setState(() {
                _selectedSessionId = session.id;
                _securityCode = null;
                _error = null;
              });
            },
            label: Text('زيارة ${session.sequence}'),
            avatar: session.isCompleted
                ? const Icon(Icons.check_circle, size: 18)
                : session.isCancelled
                ? const Icon(Icons.cancel_outlined, size: 18)
                : null,
          );
        },
      ),
    );
  }

  Widget _summaryCard() {
    final rawProgress = _schedule.daysCount <= 0
        ? 0.0
        : _schedule.completedDaysCount / _schedule.daysCount;
    final progress = rawProgress.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.titleMedium(
                  'طلب متعدد الزيارات',
                  fontWeight: FontWeight.w800,
                  textAlign: TextAlign.start,
                ),
              ),
              AppText.bodySmall(
                '${_schedule.completedDaysCount}/${_schedule.daysCount} مكتمل',
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 10),
          AppText.bodySmall(
            'إجمالي الساعات: ${_hours(_schedule.totalHours)} ساعة · الملغاة: ${_schedule.cancelledDaysCount}',
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(WorkerBookingSessionModel session) {
    final remaining = _remaining(session);
    final assignment = session.workerAssignmentState;
    final workerAmount = assignment?.workerAmount ?? assignment?.netAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WorkerAppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WorkerAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.titleMedium(
                  'الزيارة المطلوبة',
                  fontWeight: FontWeight.w800,
                  textAlign: TextAlign.start,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xffF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppText.bodySmall(
                  _statusLabel(session),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!widget.sessionDetailsOnly) ...[
            const SizedBox(height: 12),
            AppText.bodyMedium(
              _dateLabel(session),
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 4),
            AppText.bodySmall(
              '${_timeLabel(session.time)} · ${_hours(session.hours)} ساعة',
            ),
          ],
          if (workerAmount != null && !widget.sessionDetailsOnly) ...[
            const SizedBox(height: 5),
            AppText.bodySmall(
              'مستحقاتك للزيارة: ${_money(workerAmount)} ${assignment?.currency ?? 'SYP'}',
              fontWeight: FontWeight.w700,
            ),
          ],
          if (session.openTime?.liveAmount != null) ...[
            const SizedBox(height: 5),
            AppText.bodySmall(
              'المبلغ الجاري: ${_money(session.openTime!.liveAmount!)} ${session.pricing?.currency ?? assignment?.currency ?? 'SYP'}',
              fontWeight: FontWeight.w700,
            ),
          ],
          if (remaining != null && session.isInProgress) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffECFEFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('الوقت المتبقي للزيارة'),
                  const SizedBox(height: 4),
                  Text(
                    _durationLabel(remaining),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_securityCode?.securityCode != null &&
              _securityCode?.sessionId == session.id &&
              session.isAwaitingStartVerification &&
              (DateTime.tryParse(
                    _securityCode?.expiresAt ?? '',
                  )?.toLocal().isAfter(_now) ??
                  true)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('رمز بدء الزيارة'),
                  const SizedBox(height: 4),
                  SelectableText(
                    _securityCode!.securityCode!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText.bodySmall(
                    'أعطِ العميل هذا الرمز لهذه الزيارة فقط.',
                    textAlign: TextAlign.center,
                  ),
                  if (_securityCode?.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    AppText.bodySmall(
                      'ينتهي: ${CleaningArabicTimeFormatter.formatDateTime(_securityCode!.expiresAt, pattern: 'yyyy-MM-dd hh:mm a')}',
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (!widget.sessionDetailsOnly) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _openSessionDetails(session),
                icon: const Icon(Icons.info_outline),
                label: const Text('تفاصيل الزيارة'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _actionArea(session),
        ],
      ),
    );
  }

  Widget _sessionOrderContextCard(WorkerBookingSessionModel session) =>
      WorkerOrderRequirementsCard(
        order: _orderForSession(session),
        sessionId: session.id,
      );

  Widget _actionArea(WorkerBookingSessionModel session) {
    final displayedCodeExpiresAt = DateTime.tryParse(
      _securityCode?.expiresAt ?? '',
    )?.toLocal();
    final hasActiveDisplayedSecurityCode =
        _securityCode?.sessionId == session.id &&
        _securityCode?.securityCode?.isNotEmpty == true &&
        (displayedCodeExpiresAt == null ||
            displayedCodeExpiresAt.isAfter(_now));

    if (session.id == null) {
      return const _InfoBanner(
        icon: Icons.info_outline,
        text: 'هذه زيارة توافق قديمة ولا يمكن تنفيذ إجراء خاص بالزيارة عليها.',
      );
    }
    if (session.isCompleted) {
      final next = _schedule.nextSession;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoBanner(
            icon: Icons.check_circle_outline,
            text: 'تم إكمال عمل هذه الزيارة.',
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            _InfoBanner(
              icon: Icons.event_available_outlined,
              text:
                  'موعدك القادم: ${_dateLabel(next)}، ${_timeLabel(next.time)}.',
            ),
          ],
        ],
      );
    }
    if (session.isCancelled) {
      return const _InfoBanner(
        icon: Icons.cancel_outlined,
        text: 'تم إلغاء هذه الزيارة.',
      );
    }
    if (session.status == 'under_dispute') {
      return const _InfoBanner(
        icon: Icons.gavel_outlined,
        text: 'هذه الزيارة قيد المراجعة الإدارية.',
      );
    }
    if (session.status == 'awaiting_customer_completion') {
      return const _InfoBanner(
        icon: Icons.hourglass_top,
        text: 'تم إنهاء العمل. بانتظار تأكيد العميل لهذه الزيارة.',
      );
    }
    if (session.status == 'time_extension_requested') {
      return const _InfoBanner(
        icon: Icons.more_time,
        text: 'يوجد طلب تمديد مرتبط بهذه الزيارة. تعامل معه من إشعار التمديد.',
      );
    }
    if (session.openTime?.pendingExtension?.status == 'pending') {
      final minutes = session.openTime?.pendingExtension?.requestedMinutes ?? 0;
      return _OpenTimeDecisionPanel(
        icon: Icons.more_time,
        title: 'طلب تمديد وقت العامل بالساعة',
        message: 'طلب العميل تمديد هذه الزيارة $minutes دقيقة.',
        busy: _busy,
        onAccept: () => _decideOpenTimeExtension('accepted'),
        onReject: () => _decideOpenTimeExtension('rejected'),
      );
    }
    if (session.openTime?.endStatus == 'pending' ||
        session.canDecideOpenTimeEnd) {
      return _OpenTimeDecisionPanel(
        icon: Icons.stop_circle_outlined,
        title: 'طلب إنهاء عمل العامل بالساعة',
        message: 'يريد العميل إنهاء هذه الزيارة الآن.',
        busy: _busy,
        onAccept: () => _decideOpenTimeEnd('accepted'),
        onReject: () => _decideOpenTimeEnd('rejected'),
      );
    }

    Widget primary;
    if (OrderLifecyclePolicy.canStartTravelForSession(session)) {
      final tooEarly =
          !OrderLifecyclePolicy.isSessionStartTravelWithinAllowedWindow(
            session,
          );
      primary = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tooEarly) ...[
            const _InfoBanner(
              icon: Icons.schedule_outlined,
              text: OrderLifecyclePolicy.startTravelUnavailableMessage,
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: _busy || tooEarly ? null : _startTravel,
            icon: const Icon(Icons.directions_car_outlined),
            label: const Text('أنا في الطريق'),
          ),
        ],
      );
    } else if (session.canArrive) {
      primary = FilledButton.icon(
        onPressed: _busy ? null : _arrive,
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('وصلت إلى موقع المناسبة'),
      );
    } else if (session.isAwaitingStartVerification) {
      primary = FilledButton.icon(
        onPressed: _busy || hasActiveDisplayedSecurityCode
            ? null
            : _fetchSecurityCode,
        icon: const Icon(Icons.password),
        label: Text(
          hasActiveDisplayedSecurityCode
              ? 'رمز التحقق ظاهر أعلاه'
              : 'إظهار رمز التحقق لهذه الزيارة',
        ),
      );
    } else if (session.canStartWork) {
      primary = FilledButton.icon(
        onPressed: _busy ? null : _startWork,
        icon: const Icon(Icons.play_arrow),
        label: const Text('تأكيد بدء العمل'),
      );
    } else if (session.canComplete) {
      primary = FilledButton.icon(
        onPressed: _busy ? null : _complete,
        icon: const Icon(Icons.task_alt),
        label: const Text('إنهاء عمل هذه الزيارة'),
      );
    } else if (session.isInProgress) {
      primary = const _InfoBanner(
        icon: Icons.timelapse,
        text: 'العمل قيد التنفيذ. سيُفعّل الإكمال عندما يسمح النظام بذلك.',
      );
    } else {
      primary = const _InfoBanner(
        icon: Icons.schedule,
        text: 'بانتظار موعد الزيارة أو تحديث صلاحيات التنفيذ من النظام.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        const SizedBox(height: 8),
        if (OrderLifecyclePolicy.canShowSessionSos(session) ||
            session.canCancel)
          Row(
            children: [
              if (OrderLifecyclePolicy.canShowSessionSos(session))
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _sendSos,
                    icon: const Icon(Icons.sos_outlined),
                    label: const Text('SOS'),
                  ),
                ),
              if (session.canCancel) ...[
                if (OrderLifecyclePolicy.canShowSessionSos(session))
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _cancelSession,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('إلغاء الزيارة'),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  bool _shouldShowNavigationMap(WorkerBookingSessionModel session) {
    final tracker = WorkerLocationTracker.instance;
    final isTrackedTravel =
        tracker.activeBookingId == _bookingId &&
        tracker.activeSessionId == session.id;
    return !session.isTerminal &&
        (isTrackedTravel ||
            session.canArrive ||
            (session.workerAssignmentState?.startedTravelAt != null &&
                session.workerAssignmentState?.arrivedAt == null));
  }

  Widget _travelContactCard() {
    final team =
        widget.order.isMultiWorkerTeam ||
        widget.order.bookingKind == 'supervised_team';
    final name = team
        ? widget.order.supervisorContact?.firstName
        : widget.order.customer?.name;
    final phone = team
        ? widget.order.supervisorContact?.phone
        : widget.order.customer?.phone;
    return WorkerTravelContactCard(
      isTeam: team,
      name: name,
      phone: phone,
      onCall: () => _launchTravelContact('tel', phone),
      onMessage: () => _launchTravelContact('sms', phone),
    );
  }

  Future<void> _launchTravelContact(String scheme, String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    try {
      if (await launchUrl(
        Uri(scheme: scheme, path: phone.trim()),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // On Android emulators no dialer or SMS app may be installed.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheme == 'tel'
              ? 'تعذّر فتح تطبيق الاتصال على هذا الجهاز.'
              : 'تعذّر فتح تطبيق الرسائل على هذا الجهاز.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _activeSession;
    if (widget.sessionDetailsOnly && session != null) {
      return _buildSessionOrderDetails(session);
    }
    const title = 'زيارات مهمتي';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: AppText.headlineMedium(
                  title,
                  textAlign: TextAlign.start,
                ),
              ),
              IconButton(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!widget.sessionDetailsOnly) ...[
                  WorkerOrderOverviewCard(order: widget.order),
                  const SizedBox(height: 12),
                  _summaryCard(),
                  const SizedBox(height: 12),
                  _sessionSelector(),
                  const SizedBox(height: 12),
                ],
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xffB91C1C)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_busy) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 12),
                ],
                if (session == null)
                  const _InfoBanner(
                    icon: Icons.event_busy,
                    text:
                        'لم تعد لديك زيارات متاحة في هذا الطلب. قد يكون تم تغيير تعيينك لأحد أيام المناسبة.',
                  )
                else ...[
                  if (widget.sessionDetailsOnly) ...[
                    _sessionOrderContextCard(session),
                    const SizedBox(height: 12),
                    if (_shouldShowNavigationMap(session)) ...[
                      _travelContactCard(),
                      const SizedBox(height: 12),
                      _SessionNavigationMapCard(order: widget.order),
                      const SizedBox(height: 12),
                    ],
                  ],
                  _sessionCard(session),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionNavigationMapCard extends StatefulWidget {
  const _SessionNavigationMapCard({required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  State<_SessionNavigationMapCard> createState() =>
      _SessionNavigationMapCardState();
}

class _SessionNavigationMapCardState extends State<_SessionNavigationMapCard> {
  final Dio _dio = Dio();
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentLocation;
  List<LatLng> _route = const <LatLng>[];
  bool _loading = true;
  String? _error;

  LatLng? get _destination {
    final lat = widget.order.addressLatitude;
    final lng = widget.order.addressLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  String? get _textDestination {
    for (final value in [
      widget.order.bookingFullAddress,
      widget.order.propertyDetails?.address,
      widget.order.locationName,
      widget.order.neighborhoodName,
    ]) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty && text != '-') return text;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadNavigation());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      throw StateError('location_service_disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('location_permission_denied');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    ).timeout(const Duration(seconds: 12));
  }

  Future<void> _loadNavigation() async {
    final destination = _destination;
    if (destination == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _textDestination == null
            ? 'لم يزوّد الخادم الطلب بعنوان أو إحداثيات للموقع.'
            : 'العنوان متوفر، لكن إحداثيات العقار الدقيقة غير مسجّلة. يمكنك البحث عن العنوان في الخرائط والتحقق من الوجهة قبل الانطلاق.';
      });
      return;
    }

    try {
      final position = await _currentPosition();
      final current = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentLocation = current;
        _loading = false;
        _error = null;
      });
      // Show location immediately. The external directions service is optional.
      unawaited(
        _fetchRoute(current, destination).then((route) {
          if (mounted) setState(() => _route = route);
        }),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(current, 14);
        } catch (_) {}
      });
      _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 8,
            ),
          ).listen((position) {
            if (!mounted) return;
            final next = LatLng(position.latitude, position.longitude);
            setState(() => _currentLocation = next);
            try {
              _mapController.move(next, _mapController.camera.zoom);
            } catch (_) {}
          });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'تعذر تحميل الخريطة. تحقق من صلاحية الموقع والاتصال ثم حاول مرة أخرى.';
      });
    }
  }

  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
        queryParameters: const <String, dynamic>{
          'overview': 'full',
          'geometries': 'geojson',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final data = response.data;
      if (data is! Map) return const <LatLng>[];
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        return const <LatLng>[];
      }
      final geometry = (routes.first as Map)['geometry'];
      if (geometry is! Map) return const <LatLng>[];
      final coordinates = geometry['coordinates'];
      if (coordinates is! List) return const <LatLng>[];
      return coordinates
          .whereType<List>()
          .where((item) => item.length >= 2)
          .map(
            (item) => LatLng(
              (item[1] as num).toDouble(),
              (item[0] as num).toDouble(),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <LatLng>[];
    }
  }

  String? get _distanceLabel {
    final current = _currentLocation;
    final destination = _destination;
    if (current == null || destination == null) return null;
    final km =
        Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          destination.latitude,
          destination.longitude,
        ) /
        1000;
    return km >= 10
        ? '${km.toStringAsFixed(0)} كم تقريباً'
        : '${km.toStringAsFixed(1)} كم تقريباً';
  }

  Future<void> _openExternalNavigation() async {
    final destination = _destination;
    final address = _textDestination;
    if (destination == null && address == null) return;
    final uri = destination != null
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving',
          )
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': address!,
          });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.navigation_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'الطريق إلى العميل',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (_distanceLabel != null)
                  Text(
                    _distanceLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: _loading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              unawaited(_loadNavigation());
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _currentLocation == null || destination == null
                ? const Center(child: Text('تعذر تحديد المسار.'))
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation!,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.dllni.clOwner',
                      ),
                      if (_route.isNotEmpty)
                        PolylineLayer(
                          polylines: <Polyline>[
                            Polyline(
                              points: _route,
                              strokeWidth: 5,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: <Marker>[
                          Marker(
                            point: _currentLocation!,
                            width: 42,
                            height: 42,
                            child: const Icon(
                              Icons.my_location,
                              size: 34,
                              color: Colors.blue,
                            ),
                          ),
                          Marker(
                            point: destination,
                            width: 42,
                            height: 42,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: destination == null && _textDestination == null
                  ? null
                  : _openExternalNavigation,
              icon: const Icon(Icons.directions),
              label: Text(
                destination == null
                    ? 'البحث عن العنوان في الخرائط'
                    : 'فتح الملاحة',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _OpenTimeDecisionPanel extends StatelessWidget {
  const _OpenTimeDecisionPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xffFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffF59E0B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xff92400E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: busy ? null : onReject,
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: busy ? null : onAccept,
                    child: const Text('قبول'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
