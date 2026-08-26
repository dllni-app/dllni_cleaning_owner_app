import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/location/worker_location_tracker.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/worker_session_remote_data_source.dart';
import 'package:flutter/material.dart';

class MultiDayOrderDetailsBody extends StatefulWidget {
  const MultiDayOrderDetailsBody({
    super.key,
    required this.order,
    required this.initialSchedule,
    this.initialSelectedSessionId,
    this.onScheduleChanged,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final WorkerBookingScheduleModel initialSchedule;
  final int? initialSelectedSessionId;
  final ValueChanged<WorkerBookingScheduleModel>? onScheduleChanged;

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
  }

  @override
  void didUpdateWidget(covariant MultiDayOrderDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSchedule != widget.initialSchedule) {
      _schedule = widget.initialSchedule;
      if (_schedule.sessionById(_selectedSessionId) == null) {
        _selectedSessionId = _resolveInitialSessionId();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  Future<void> _refresh() async {
    final bookingId = _bookingId;
    if (bookingId == null) return;
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .fetchBookingSchedule(bookingId);
      final schedule = result.schedule;
      if (!mounted || schedule == null) return;
      setState(() {
        _schedule = schedule;
        _error = null;
        if (_schedule.sessionById(_selectedSessionId) == null) {
          _selectedSessionId = _resolveInitialSessionId();
        }
      });
      widget.onScheduleChanged?.call(schedule);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحديث حالة جلسات المناسبة.');
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('overlap') || text.contains('conflict')) {
      return 'تعذر تنفيذ العملية بسبب تعارض في الجدول.';
    }
    return 'تعذر تنفيذ العملية. حدّث الجلسة وتحقق من الصلاحيات ثم حاول مرة أخرى.';
  }

  Future<void> _startTravel() async {
    final bookingId = _bookingId;
    final session = _activeSession;
    final sessionId = session?.id;
    if (bookingId == null ||
        session == null ||
        sessionId == null ||
        !session.canStartTravel) {
      return;
    }
    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().startTravel(
        bookingId: bookingId,
        sessionId: sessionId,
      );
      await WorkerLocationTracker.instance.start(
        bookingId,
        sessionId: sessionId,
      );
    });
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
    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().arrive(
        bookingId: bookingId,
        sessionId: sessionId,
      );
      await WorkerLocationTracker.instance.stop();
    });
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

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .fetchSecurityCode(
            bookingId: bookingId,
            sessionId: sessionId,
          );
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
    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().startWork(
        bookingId: bookingId,
        sessionId: sessionId,
      );
      await WorkerLocationTracker.instance.stop();
    });
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
      title: 'إنهاء عمل هذه الجلسة',
      hint: 'رسالة الإكمال للعميل (اختياري)',
      isRequired: false,
      maxLength: 1000,
    );
    if (message == null) return;

    await _runAction(() async {
      await getIt<WorkerSessionRemoteDataSource>().complete(
        bookingId: bookingId,
        sessionId: sessionId,
        completionMessage: message,
      );
    });
  }

  Future<void> _cancelSession() async {
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
      title: 'إلغاء هذه الجلسة',
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
        session.isTerminal) {
      return;
    }

    final message = await _askText(
      title: 'إرسال SOS للجلسة ${session.sequence}',
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
          'emergency_type': 'other',
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
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return switch (session.status) {
      'scheduled' => 'مجدول',
      'worker_assigned' => session.startedTravelAt != null
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
    final started = DateTime.tryParse(session.workStartedAt ?? '');
    if (started == null || session.hours <= 0) return null;
    final end = started.add(
      Duration(minutes: (session.hours * 60).round()),
    );
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
            label: Text('الجلسة ${session.sequence}'),
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
                  'طلب متعدد الجلسات',
                  fontWeight: FontWeight.w800,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.titleMedium(
                  'الجلسة ${session.sequence} من ${_schedule.daysCount}',
                  fontWeight: FontWeight.w800,
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
          const SizedBox(height: 12),
          AppText.bodyMedium(_dateLabel(session), fontWeight: FontWeight.w700),
          const SizedBox(height: 4),
          AppText.bodySmall(
            '${_timeLabel(session.time)} · ${_hours(session.hours)} ساعة',
          ),
          if (workerAmount != null) ...[
            const SizedBox(height: 5),
            AppText.bodySmall(
              'مستحقاتك لهذه الجلسة: ${_money(workerAmount)} ${assignment?.currency ?? 'SYP'}',
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
                  const Text('الوقت المتبقي للجلسة'),
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
              _securityCode?.sessionId == session.id) ...[
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
                  const Text('رمز بدء هذه الجلسة'),
                  const SizedBox(height: 4),
                  SelectableText(
                    _securityCode!.securityCode!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  if (_securityCode?.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    AppText.bodySmall('ينتهي: ${_securityCode!.expiresAt}'),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _actionArea(session),
        ],
      ),
    );
  }

  Widget _actionArea(WorkerBookingSessionModel session) {
    if (session.id == null) {
      return const _InfoBanner(
        icon: Icons.info_outline,
        text: 'هذه جلسة توافق قديمة ولا يمكن تنفيذ إجراء خاص بالجلسة عليها.',
      );
    }
    if (session.isCompleted) {
      final next = _schedule.nextSession;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoBanner(
            icon: Icons.check_circle_outline,
            text: 'تم إكمال عمل هذه الجلسة.',
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            _InfoBanner(
              icon: Icons.event_available_outlined,
              text: 'موعدك القادم: ${_dateLabel(next)}، ${_timeLabel(next.time)}.',
            ),
          ],
        ],
      );
    }
    if (session.isCancelled) {
      return const _InfoBanner(
        icon: Icons.cancel_outlined,
        text: 'تم إلغاء هذه الجلسة.',
      );
    }
    if (session.status == 'under_dispute') {
      return const _InfoBanner(
        icon: Icons.gavel_outlined,
        text: 'هذه الجلسة قيد المراجعة الإدارية.',
      );
    }
    if (session.status == 'awaiting_customer_completion') {
      return const _InfoBanner(
        icon: Icons.hourglass_top,
        text: 'تم إنهاء العمل. بانتظار تأكيد العميل لهذه الجلسة.',
      );
    }
    if (session.status == 'time_extension_requested') {
      return const _InfoBanner(
        icon: Icons.more_time,
        text: 'يوجد طلب تمديد مرتبط بهذه الجلسة. تعامل معه من إشعار التمديد.',
      );
    }

    Widget primary;
    if (session.canStartTravel) {
      primary = FilledButton.icon(
        onPressed: _busy ? null : _startTravel,
        icon: const Icon(Icons.directions_car_outlined),
        label: const Text('بدء التوجه لهذه الجلسة'),
      );
    } else if (session.canArrive) {
      primary = FilledButton.icon(
        onPressed: _busy ? null : _arrive,
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('وصلت إلى موقع المناسبة'),
      );
    } else if (session.isAwaitingStartVerification) {
      primary = FilledButton.icon(
        onPressed: _busy ? null : _fetchSecurityCode,
        icon: const Icon(Icons.password),
        label: const Text('إظهار رمز التحقق لهذه الجلسة'),
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
        label: const Text('إنهاء عمل هذه الجلسة'),
      );
    } else if (session.isInProgress) {
      primary = const _InfoBanner(
        icon: Icons.timelapse,
        text: 'العمل قيد التنفيذ. سيُفعّل الإكمال عندما يسمح النظام بذلك.',
      );
    } else {
      primary = const _InfoBanner(
        icon: Icons.schedule,
        text: 'بانتظار موعد الجلسة أو تحديث صلاحيات التنفيذ من النظام.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _sendSos,
                icon: const Icon(Icons.sos_outlined),
                label: const Text('SOS'),
              ),
            ),
            if (session.canCancel) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _cancelSession,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('إلغاء الجلسة'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _activeSession;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: AppText.headlineMedium(
                  'تفاصيل الطلب ${widget.order.bookingNumber ?? ''}',
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
                _summaryCard(),
                const SizedBox(height: 12),
                _sessionSelector(),
                const SizedBox(height: 12),
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
                    text: 'لا توجد جلسة متاحة.',
                  )
                else
                  _sessionCard(session),
              ],
            ),
          ),
        ),
      ],
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
