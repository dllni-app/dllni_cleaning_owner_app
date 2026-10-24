import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState, Page;

import '../../contracts/common.dart';
import '../../contracts/models.dart';
import '../../contracts/navigation.dart';
import '../../contracts/ports.dart';
import '../../contracts/requests.dart';
import '../../design_system/design_system.dart';
import 'catalog_ar.dart';
import 'catalog_en.dart';

/// Fixture-capable finance feature. No payment, deposit or settlement writes.
class WorkerFinanceModule extends StatefulWidget {
  const WorkerFinanceModule({
    super.key,
    required this.finance,
    required this.runtime,
    required this.session,
    required this.onNavigate,
    this.destination = WorkerDestination.earnings,
    this.entityId,
    this.initialEarningsRange,
  });

  final FinancePort finance;
  final WorkerRuntimePort runtime;
  final WorkerSessionContext session;
  final ValueChanged<RouteIntent> onNavigate;
  final WorkerDestination destination;
  final String? entityId;
  /// Optional server-approved inclusive business-day filter, never computed
  /// from booking amounts or device-local work timestamps.
  final DateRange? initialEarningsRange;

  @override
  State<WorkerFinanceModule> createState() => _WorkerFinanceModuleState();
}

class _WorkerFinanceModuleState extends State<WorkerFinanceModule> {
  ReadResult<Object>? _result;
  bool _loading = true;
  bool _sending = false;
  bool _unknown = false;
  bool _uncertainReviewReady = false;
  String? _message;
  int _epoch = 0;
  int _page = 1;
  DateRange? _earningsRange;
  final _draft = TextEditingController();
  StreamSubscription<DomainInvalidation>? _invalidationSubscription;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';
  String _tr(String ar, String en) => _arabic ? ar : en;
  String _label(String code) => (_arabic ? financeLabelsAr : financeLabelsEn)[code]
      ?? _tr('الحالة غير متاحة', 'Status unavailable');

  /// Source families describe the work unit, not its private backing key.
  /// A service name requires a future approved worker-safe contract field.
  String _earningSourceLabel(EarningEntryView entry) {
    if (entry.key.startsWith('session_assignment:')) {
      return _tr('زيارة عمل مكتملة', 'Completed work visit');
    }
    if (entry.key.startsWith('booking_assignment:')) {
      return _tr('تكليف عمل مكتمل', 'Completed work assignment');
    }
    return _tr('حجز عمل مكتمل', 'Completed work booking');
  }

  /// An opaque ID may only be disclosed as a short support reference.
  /// Reject whitespace, email-like strings, URLs and arbitrary private data.
  String? _safeReference(String? value, {bool sourceKey = false}) {
    if (value == null) return null;
    final candidate = sourceKey ? value.split(':').last : value;
    if (!RegExp(r'^[A-Za-z0-9_-]{1,24}$').hasMatch(candidate)) {
      return null;
    }
    return _arabic ? '\u2066$candidate\u2069' : candidate;
  }

  String _workDate(String raw) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return _tr('التاريخ غير متاح', 'Date unavailable');
    }
    return _arabic ? '\u2066$raw\u2069' : raw;
  }

  /// Every instant is shown in UTC explicitly. Device-local time is never
  /// mistaken for the server's Damascus business calendar date.
  String _instantLabel(DateTime instant) {
    final utc = instant.toUtc();
    final stamp = '${_dateString(utc)} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')} UTC';
    return _arabic ? '\u2066$stamp\u2069' : stamp;
  }

  String _componentLabel(String key) => switch (key) {
    'worker_amount' => _tr('مستحقات العامل', 'Worker allocation'),
    'service_share_amount' => _tr('حصة الخدمة', 'Service share'),
    'travel_fee' => _tr('بدل التنقل', 'Travel fee'),
    'admin_margin_amount' => _tr('الهامش الإداري', 'Administration margin'),
    _ => _tr('بند مخصصات آخر', 'Other allocation component'),
  };

  String _senderLabel(String label) => switch (label.trim().toLowerCase()) {
    'worker' => _tr('العامل', 'Worker'),
    'admin' || 'administrator' => _tr('الإدارة', 'Administration'),
    'support' => _tr('الدعم', 'Support'),
    'customer' => _tr('العميل', 'Customer'),
    _ => _tr('مشارك', 'Participant'),
  };

  String _disputeTitle(String id) {
    final reference = _safeReference(id);
    return reference == null
        ? _tr('اعتراض', 'Dispute')
        : '${_tr('اعتراض', 'Dispute')} $reference';
  }
  bool get _sessionValid {
    final actual = widget.runtime.context;
    return actual != null &&
        widget.runtime.phase == RuntimePhase.signedIn &&
        actual.userId == widget.session.userId &&
        actual.workerId == widget.session.workerId &&
        actual.generation == widget.session.generation;
  }
  bool get _online => widget.runtime.connection == ConnectionState.online;

  bool _canOpenMission(EarningEntryView entry) {
    final scope = entry.scope;
    if (scope.bookingId.trim().isEmpty) return false;
    if (entry.key.startsWith('session_assignment:')) {
      return scope.sessionId != null && scope.assignmentId != null;
    }
    if (entry.key.startsWith('booking_assignment:')) {
      return scope.sessionId == null && scope.assignmentId != null;
    }
    if (entry.key.startsWith('legacy_booking:')) {
      return scope.sessionId == null;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _earningsRange = widget.initialEarningsRange;
    _observeInvalidations();
    _load();
  }

  void _observeInvalidations() {
    _invalidationSubscription?.cancel();
    _invalidationSubscription = widget.runtime.invalidations.listen((event) {
      if (!mounted || !_sessionValid || event.generation != widget.session.generation) return;
      if (event.topic == InvalidationTopic.earnings ||
          event.topic == InvalidationTopic.deposit ||
          event.topic == InvalidationTopic.dispute) {
        if (!_sending) _load();
      }
    });
  }

  @override
  void didUpdateWidget(covariant WorkerFinanceModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.userId != widget.session.userId ||
        oldWidget.session.workerId != widget.session.workerId ||
        oldWidget.session.generation != widget.session.generation ||
        oldWidget.destination != widget.destination ||
        oldWidget.entityId != widget.entityId ||
        oldWidget.runtime != widget.runtime) {
      _epoch++;
      _draft.clear();
      _unknown = false;
      _uncertainReviewReady = false;
      _sending = false;
      _page = 1;
      _earningsRange = widget.initialEarningsRange;
      _result = null;
      if (oldWidget.runtime != widget.runtime) _observeInvalidations();
      _load();
    }
  }

  @override
  void dispose() {
    _epoch++;
    _invalidationSubscription?.cancel();
    _draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Do not orphan an in-flight dispute message. Its result is authoritative
    // only for the exact user, generation, dispute and command epoch.
    if (_sending) return;
    final token = ++_epoch;
    setState(() {
      _loading = true;
      _message = null;
      _uncertainReviewReady = false;
      _result = null; // Never reuse confidential finance or dispute data.
    });
    if (!_sessionValid) {
      if (mounted && token == _epoch) setState(() => _loading = false);
      return;
    }
    ReadResult<Object> result;
    try {
      switch (widget.destination) {
        case WorkerDestination.earningDetail:
          result = await widget.finance.fetchEarning(widget.entityId!);
        case WorkerDestination.depositAccount:
          result = await widget.finance.fetchDeposit();
        case WorkerDestination.depositLedger:
          result = await widget.finance.fetchDepositLedger(LedgerQuery(page: PageQuery(page: _page)));
        case WorkerDestination.disputes:
          result = await widget.finance.fetchDisputes(DisputeQuery(page: PageQuery(page: _page)));
        case WorkerDestination.disputeThread:
          result = await widget.finance.fetchDispute(widget.entityId!);
        default:
          result = await widget.finance.fetchEarnings(EarningsQuery(
              dates: _earningsRange, page: PageQuery(page: _page)));
      }
    } catch (_) {
      result = ReadFailure<Object>(PortFailure(kind: FailureKind.server, reasonCode: 'read_unavailable'));
    }
    if (result is ReadSuccess<Object>) {
      final value = result.value;
      if ((widget.destination == WorkerDestination.disputeThread &&
              (value is! DisputeView || value.id != widget.entityId)) ||
          (widget.destination == WorkerDestination.earningDetail &&
              (value is! EarningEntryView || value.key != widget.entityId))) {
        result = ReadFailure<Object>(
          PortFailure(kind: FailureKind.notFound, reasonCode: 'scope_mismatch'),
        );
      }
    }
    if (!mounted || token != _epoch || !_sessionValid) return;
    setState(() {
      _result = result;
      _loading = false;
      // An uncertain reply may only be reconsidered after a fresh, scoped
      // server thread read. Do not auto-replay the prior message.
      _uncertainReviewReady = _unknown &&
          widget.destination == WorkerDestination.disputeThread &&
          result is ReadSuccess<Object> &&
          result.freshness == ReadFreshness.fresh &&
          result.value is DisputeView;
    });
  }

  void _nav(WorkerDestination destination, {String? id, WorkScope? scope}) {
    widget.onNavigate(RouteIntent(
      destination: destination,
      entityId: id,
      scope: scope,
      origin: RouteOrigin.finance,
    ));
  }

  String _dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _parseDay(String date) => DateTime(
      int.parse(date.substring(0, 4)), int.parse(date.substring(5, 7)),
      int.parse(date.substring(8, 10)));

  Future<void> _chooseEarningsDates() async {
    if (_loading || _sending || !_sessionValid) return;
    final originalEpoch = _epoch;
    final current = _earningsRange;
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: current == null ? null : DateTimeRange(
        start: _parseDay(current.from), end: _parseDay(current.to)),
      helpText: _tr('حدد تاريخ العمل', 'Select work dates'),
    );
    if (!mounted || originalEpoch != _epoch || !_sessionValid || chosen == null) return;
    final range = DateRange(
      from: _dateString(chosen.start), to: _dateString(chosen.end));
    setState(() { _earningsRange = range; _page = 1; });
    await _load();
  }

  void _clearEarningsDates() {
    if (_earningsRange == null || _loading || _sending || !_sessionValid) return;
    setState(() { _earningsRange = null; _page = 1; });
    _load();
  }

  Future<void> _sendReply(DisputeView dispute) async {
    final body = _draft.text.trim();
    if (_sending || _unknown || !_sessionValid ||
        widget.runtime.connection != ConnectionState.online ||
        !dispute.canReply || body.isEmpty || body.length > 2000) {
      return;
    }
    final token = ++_epoch;
    setState(() { _sending = true; _message = null; });
    CommandResult result;
    try {
      result = await widget.finance.postDisputeMessage(dispute.id, body);
    } catch (_) {
      result = CommandResult(status: CommandStatus.outcomeUnknown);
    }
    if (!mounted || token != _epoch || !_sessionValid) return;
    final denied = result.status == CommandStatus.rejected &&
        const {
          'unavailable', 'not_found', 'session_expired', 'scope_changed',
          'forbidden', 'not_assigned', 'assignment_revoked',
        }.contains(result.reasonCode);
    setState(() {
      _sending = false;
      if (denied) {
        // A rejected write can itself revoke access to the previously read
        // thread. Discard its messages, authorization, and private draft now.
        _result = ReadFailure<Object>(
          PortFailure(kind: FailureKind.forbidden, reasonCode: 'unavailable'),
        );
        _loading = false;
        _unknown = false;
        _uncertainReviewReady = false;
        _draft.clear();
        _message = null;
      } else if (result.status == CommandStatus.confirmed) {
        _draft.clear();
        _message = _tr('تم إرسال الرسالة', 'Message sent');
      } else if (result.status == CommandStatus.outcomeUnknown) {
        _unknown = true;
        _uncertainReviewReady = false;
        _message = _tr('لم يتم تأكيد الإرسال. تحقق من المحادثة قبل إعادة المحاولة.',
            'Delivery is unconfirmed. Check the thread before retrying.');
      } else {
        _message = _tr('تعذر إرسال الرسالة. يمكنك إعادة المحاولة.', 'Message was rejected. You can retry.');
      }
    });
    if (result.status == CommandStatus.confirmed) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.destination) {
      WorkerDestination.earningDetail => _tr('تفاصيل الأرباح', 'Earning detail'),
      WorkerDestination.depositAccount => _tr('حساب الإيداع', 'Deposit account'),
      WorkerDestination.depositLedger => _tr('سجل الإيداع', 'Deposit ledger'),
      WorkerDestination.disputes => _tr('الاعتراضات', 'Disputes'),
      WorkerDestination.disputeThread => _tr('محادثة الاعتراض', 'Dispute thread'),
      _ => _tr('الأرباح', 'Earnings'),
    };
    final result = _result;
    final child = !_sessionValid
        ? WrFeedbackPanel(kind: WrFeedbackKind.forbidden, title: _tr('يرجى تسجيل الدخول مجدداً', 'Sign in again'))
        : _loading
            ? WrFeedbackPanel(kind: WrFeedbackKind.loading, title: _tr('جاري التحميل', 'Loading'))
            : result is ReadFailure<Object>
                ? WrFeedbackPanel(
                    kind: result.failure.kind == FailureKind.forbidden || result.failure.kind == FailureKind.notFound
                        ? WrFeedbackKind.forbidden : WrFeedbackKind.initialError,
                    title: _tr('لا يمكن عرض هذه البيانات', 'Data unavailable'),
                    retryLabel: _tr('إعادة المحاولة', 'Retry'), onRetry: _load)
                : result is ReadSuccess<Object>
                    ? _body(result.value, result.freshness)
                    : WrFeedbackPanel(kind: WrFeedbackKind.unavailable, title: _tr('غير متاح', 'Unavailable'));
    return WrPageFrame(
      title: title,
      headerAction: WrIconAction(icon: Icons.refresh, label: _tr('تحديث', 'Refresh'),
          onPressed: _loading || _sending ? null : _load),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_message != null) ...[
          WrEligibilityNotice(title: _tr('حالة الطلب', 'Request status'), message: _message!),
          const SizedBox(height: WrSpace.md),
        ],
        child,
      ]),
    );
  }

  Widget _body(Object data, ReadFreshness freshness) {
    if ((!_online || freshness != ReadFreshness.fresh) &&
        (data is DisputeView || data is DepositView || data is EarningEntryView ||
            data is Page<DisputeView> || data is Page<DepositLedgerEntryView>)) {
      return WrFeedbackPanel(kind: WrFeedbackKind.offline, title: _tr('يلزم الاتصال لعرض البيانات', 'Connect to view this information'));
    }
    if (data is EarningsView) return _earnings(data, freshness);
    if (data is EarningEntryView) return _earning(data);
    if (data is DepositView) return _deposit(data);
    if (data is Page<DepositLedgerEntryView>) return _ledger(data);
    if (data is Page<DisputeView>) return _disputes(data);
    if (data is DisputeView) return _thread(data);
    return WrFeedbackPanel(kind: WrFeedbackKind.unavailable, title: _tr('البيانات غير متاحة', 'Data unavailable'));
  }

  Widget _earnings(EarningsView data, ReadFreshness freshness) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (freshness != ReadFreshness.fresh) WrEligibilityNotice(
          title: _tr('بيانات غير محدثة', 'Not current'),
          message: _tr('هذه أرقام للعرض فقط', 'Read-only historical summary')),
      WrSectionPanel(title: _tr('تاريخ العمل', 'Work date range'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_earningsRange == null ? _tr('كل الوقت', 'All time')
              : '${_earningsRange!.from} — ${_earningsRange!.to}',
            textDirection: TextDirection.ltr),
          WrActionButton(label: _tr('تحديد التواريخ', 'Select dates'),
              role: WrActionRole.secondary,
              onPressed: _online && !_loading ? _chooseEarningsDates : null),
          if (_earningsRange != null)
            WrActionButton(label: _tr('مسح التصفية', 'Clear date filter'),
                role: WrActionRole.secondary,
                onPressed: _online && !_loading ? _clearEarningsDates : null),
        ])),
      const SizedBox(height: WrSpace.md),
      WrSectionPanel(title: _tr('أرباح العمل المكتمل', 'Completed-work earnings'),
          subtitle: data.periodLabel,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final amount in data.completedTotals.values)
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: WrAmountText(
                  amount: amount, unavailableLabel: _tr('غير متاح', 'Unavailable'))),
            if (data.completedTotals.isEmpty) Text(_tr('لا توجد مبالغ مؤكدة', 'No known amounts')),
            if (data.incompleteEntries > 0) Text(_tr('توجد تخصيصات غير متاحة: ${data.incompleteEntries}',
                'Allocations unavailable: ${data.incompleteEntries}')),
          ])),
      const SizedBox(height: WrSpace.md),
      WrSectionPanel(title: _tr('العمليات المكتملة', 'Completed entries'),
          child: data.entries.items.isEmpty
              ? Text(_tr('لا توجد أرباح مسجلة', 'No entries found'))
              : Column(children: [
                  for (final entry in data.entries.items)
                    WrListRow(title: _earningSourceLabel(entry),
                      subtitle: '${_tr('تاريخ العمل', 'Work date')}: ${_workDate(entry.completedDate)} · ${_label(entry.reconciliationState)}',
                      trailing: WrAmountText(amount: entry.authoritativeAmount,
                          unavailableLabel: _tr('المبلغ غير متاح', 'Amount unavailable')),
                      onTap: () => _nav(WorkerDestination.earningDetail, id: entry.key)),
                ])),
      _more(data.entries.page, data.entries.lastPage, data.entries.total),
      const SizedBox(height: WrSpace.md),
      WrActionButton(label: _tr('حساب الإيداع منفصل', 'View separate deposit account'),
        role: WrActionRole.secondary, onPressed: () => _nav(WorkerDestination.depositAccount)),
      const SizedBox(height: WrSpace.sm),
      WrActionButton(label: _tr('الاعتراضات', 'Disputes'), role: WrActionRole.secondary,
        onPressed: () => _nav(WorkerDestination.disputes)),
    ],
  );

  Widget _earning(EarningEntryView e) => WrSectionPanel(
    title: _earningSourceLabel(e),
    subtitle: '${_tr('تاريخ العمل', 'Work date')}: ${_workDate(e.completedDate)} · ${_label(e.reconciliationState)}',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_safeReference(e.key, sourceKey: true) case final reference?)
        WrListRow(title: _tr('مرجع للدعم', 'Support reference'), subtitle: reference),
      WrAmountText(amount: e.authoritativeAmount,
          unavailableLabel: _tr('لا يوجد تخصيص مالي متاح', 'Allocation unavailable')),
      for (final part in e.frozenBreakdown.entries)
        WrListRow(title: _componentLabel(part.key),
          trailing: WrAmountText(amount: part.value, unavailableLabel: '—')),
      Text(_tr('الأرباح المسجلة منفصلة عن حساب الإيداع والديون.',
          'Completed-work earnings are separate from deposit and debt balances.')),
      const SizedBox(height: WrSpace.sm),
      WrActionButton(label: _tr('عرض المهمة', 'View mission'), role: WrActionRole.secondary,
          onPressed: _canOpenMission(e) ? () => _nav(WorkerDestination.mission, scope: e.scope) : null),
    ]),
  );

  Widget _deposit(DepositView d) => Column(children: [
    WrSectionPanel(title: _tr('رصيد الإيداع', 'Deposit balance'),
      child: WrAmountText(amount: d.currentBalance, unavailableLabel: _tr('غير متاح', 'Unavailable'))),
    const SizedBox(height: WrSpace.md),
    WrSectionPanel(title: _tr('رصيد الدين', 'Debt balance'),
      child: WrAmountText(amount: d.debtBalance, unavailableLabel: _tr('غير متاح', 'Unavailable'))),
    const SizedBox(height: WrSpace.md),
    WrSectionPanel(title: _tr('الأهلية المالية', 'Financial eligibility'), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WrStatusBadge(label: d.financiallyEligible ? _tr('مؤهل', 'Eligible') : _tr('غير مؤهل', 'Not eligible'),
          tone: d.financiallyEligible ? WrStatusTone.success : WrStatusTone.warning),
        Text(_label(d.accountStatus)),
        for (final reason in d.restrictionCodes) Text(_label(reason)),
        WrListRow(title: _tr('الحد الأدنى', 'Minimum balance'),
          trailing: WrAmountText(amount: d.minimumBalance, unavailableLabel: '—')),
        WrListRow(title: _tr('حد الدين المتاح', 'Debt capacity'),
          trailing: WrAmountText(amount: d.debtCapacity, unavailableLabel: '—')),
      ])),
    const SizedBox(height: WrSpace.md),
    WrActionButton(label: _tr('سجل المعاملات', 'Transaction history'),
      onPressed: () => _nav(WorkerDestination.depositLedger)),
  ]);

  Widget _ledger(Page<DepositLedgerEntryView> ledger) => Column(children: [
    if (ledger.items.isEmpty)
      Text(_tr('لا توجد معاملات', 'No transactions')),
    for (final item in ledger.items)
      WrSectionPanel(title: _label(item.status), subtitle: _instantLabel(item.occurredAt),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WrAmountText(amount: item.amount, unavailableLabel: '—'),
          if (_safeReference(item.reference) case final reference?)
            WrListRow(title: _tr('مرجع للدعم', 'Support reference'), subtitle: reference),
        ])),
    _more(ledger.page, ledger.lastPage, ledger.total),
  ]);

  Widget _disputes(Page<DisputeView> disputes) => Column(children: [
    if (disputes.items.isEmpty)
      Text(_tr('لا توجد اعتراضات ظاهرة', 'No visible disputes')),
    for (final d in disputes.items)
      WrListRow(title: _disputeTitle(d.id),
        subtitle: '${_tr('الحالة', 'Status')}: ${_label(d.status)}',
        onTap: () => _nav(WorkerDestination.disputeThread, id: d.id)),
    _more(disputes.page, disputes.lastPage, disputes.total),
  ]);

  Widget _thread(DisputeView d) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      WrSectionPanel(
        title: _disputeTitle(d.id),
        subtitle: '${_tr('الحالة الحالية', 'Current status')}: ${_label(d.status)}',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (d.statusHistory.isNotEmpty) ...[
            Text(_tr('سجل الحالات', 'Status history')),
            for (final status in d.statusHistory)
              Text(_label(status)),
            const SizedBox(height: WrSpace.sm),
          ],
          if (d.messages.isEmpty)
            Text(_tr('لا توجد رسائل', 'No messages')),
          for (final m in d.messages)
            WrListRow(title: '${_senderLabel(m.senderLabel)} · ${_instantLabel(m.sentAt)}',
                subtitle: m.body),
        ])),
      const SizedBox(height: WrSpace.md),
      if (_unknown) WrEligibilityNotice(title: _tr('النتيجة غير مؤكدة', 'Outcome unknown'),
        message: _tr('حدّث المحادثة وراجع الرسائل قبل إنشاء رسالة جديدة. لن نعيد إرسال الرسالة السابقة تلقائياً.',
            'Refresh and review the thread before composing a new message. The previous message will not be resent.')),
      if (_unknown && _uncertainReviewReady)
        WrActionButton(
          label: _tr('راجعت المحادثة، ابدأ رسالة جديدة', 'I reviewed the thread; compose a new message'),
          role: WrActionRole.secondary,
          onPressed: _online && !_loading && !_sending ? () {
            setState(() {
              _unknown = false;
              _uncertainReviewReady = false;
              _draft.clear(); // Never silently retry the uncertain payload.
              _message = _tr('يمكنك كتابة رسالة جديدة', 'You may compose a new message');
            });
          } : null,
        ),
      if (!d.canReply)
        Text(_tr('الرد غير متاح لهذا الاعتراض', 'Replies are unavailable for this dispute')),
      TextField(controller: _draft, maxLength: 2000, maxLines: 4,
        onChanged: (_) => setState(() {}),
        enabled: d.canReply && !_sending && !_unknown && widget.runtime.connection == ConnectionState.online,
        decoration: InputDecoration(labelText: _tr('رسالتك', 'Your message'))),
      WrActionButton(label: _tr('إرسال الرسالة', 'Send message'), busy: _sending,
        busyLabel: _tr('جاري الإرسال', 'Sending'),
        onPressed: _draft.text.trim().isNotEmpty && !_sending && !_unknown && d.canReply &&
            widget.runtime.connection == ConnectionState.online ? () => _sendReply(d) : null),
    ],
  );

  Widget _more(int page, int lastPage, int total) => Padding(
    padding: const EdgeInsets.only(top: WrSpace.sm),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_arabic
          ? 'الصفحة $page من $lastPage · المجموع $total'
          : 'Page $page of $lastPage · Total $total'),
      Wrap(alignment: WrapAlignment.end, spacing: WrSpace.xs, children: [
        if (page > 1) TextButton(onPressed: _online && !_loading && !_sending
            ? () { setState(() => _page = page - 1); _load(); } : null,
            child: Text(_tr('السابق', 'Previous'))),
        if (page < lastPage) TextButton(onPressed: _online && !_loading && !_sending
            ? () { setState(() => _page = page + 1); _load(); } : null,
            child: Text(_tr('التالي', 'Next'))),
      ]),
    ]),
  );
}
