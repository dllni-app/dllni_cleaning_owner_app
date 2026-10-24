import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart' hide ConnectionState, Page;

import '../../contracts/common.dart';
import '../../contracts/models.dart';
import '../../contracts/navigation.dart';
import '../../contracts/ports.dart';
import '../../contracts/requests.dart';
import '../../design_system/design_system.dart';
import 'catalog_ar.dart';
import 'catalog_en.dart';

/// Notification, configured support-channel, and scoped SOS presentation.
/// Root owns push listeners, authentication, route hydration and URL launching.
class WorkerCommunicationsModule extends StatefulWidget {
  const WorkerCommunicationsModule({
    super.key,
    required this.communications,
    required this.runtime,
    required this.session,
    required this.onNavigate,
    this.destination = WorkerDestination.notifications,
    this.scope,
    this.sosAuthorized = false,
    this.allowedSosReasons = const [],
    this.onOpenContact,
    this.verifiedEmergencyPhone,
    this.localizedReasonLabels = const {},
  });
  final CommunicationsPort communications;
  final WorkerRuntimePort runtime;
  final WorkerSessionContext session;
  final ValueChanged<RouteIntent> onNavigate;
  final WorkerDestination destination;
  final WorkScope? scope;

  /// Verified by root/mission from current server authorization, not inferred.
  final bool sosAuthorized;

  /// Server/contract-approved category codes. Empty => fail closed.
  final List<String> allowedSosReasons;

  /// Only host may implement an approved dialer/URL launcher.
  final Future<bool> Function(SupportContactView)? onOpenContact;

  /// Configured, verified phone contact; never invented in this widget.
  final SupportContactView? verifiedEmergencyPhone;
  final Map<String, String> localizedReasonLabels;

  @override
  State<WorkerCommunicationsModule> createState() => _CommunicationsState();
}

class _CommunicationsState extends State<WorkerCommunicationsModule> {
  ReadResult<Object>? _result;
  bool _busy = false;
  bool _loading = true;
  bool _unreadOnly = false;
  bool _unknown = false;
  String? _message;
  String? _reason;
  int _epoch = 0;
  int _page = 1;
  final _sosMessage = TextEditingController();
  StreamSubscription<DomainInvalidation>? _invalidationSubscription;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;
  String _channelLabel(String type) =>
      (_ar ? communicationChannelsAr : communicationChannelsEn)[_contactKind(
        type,
      )] ??
      _t('قناة دعم', 'Support channel');

  // Canonical types stay aligned with the frozen launcher contract; only
  // familiar configuration aliases are accepted. Unknown types fail closed.
  String? _contactKind(String raw) => switch (raw.trim().toLowerCase()) {
    'phone' || 'tel' || 'telephone' => 'phone',
    'email' || 'mail' || 'mailto' => 'email',
    'website' || 'web' || 'url' => 'website',
    'whatsapp' => 'whatsapp',
    _ => null,
  };

  String _sentAt(DateTime time) {
    final local = time.toLocal();
    // Some isolated/embedded hosts override language while their localized
    // Material delegate has not loaded. Keep the timestamp readable instead
    // of crashing the notification inbox; root supplies localization in app.
    final formatter = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    final date =
        formatter?.formatMediumDate(local) ??
        '${local.year.toString().padLeft(4, '0')}-'
            '${local.month.toString().padLeft(2, '0')}-'
            '${local.day.toString().padLeft(2, '0')}';
    final clock =
        formatter?.formatTimeOfDay(
          TimeOfDay.fromDateTime(local),
          alwaysUse24HourFormat: true,
        ) ??
        '${local.hour.toString().padLeft(2, '0')}:'
            '${local.minute.toString().padLeft(2, '0')}';
    // Material localizations may use Arabic/Persian numerals, but this app's
    // reference and timestamp display policy always uses ASCII digits.
    return '$date · $clock'.replaceAllMapped(RegExp(r'[٠-٩۰-۹]'), (match) {
      final code = match[0]!.runes.single;
      return '${code >= 0x6f0 ? code - 0x6f0 : code - 0x660}';
    });
  }

  String _promptKindLabel(String? kind) => switch (kind) {
    'extension_request' => _t('طلب تمديد الوقت', 'Time extension request'),
    'schedule_change' => _t('طلب تغيير الموعد', 'Schedule change request'),
    'price_adjustment' => _t('طلب تعديل السعر', 'Price adjustment request'),
    'completion_decision' => _t(
      'طلب مراجعة الإكمال',
      'Completion review request',
    ),
    'open_time_end' => _t('طلب إنهاء الوقت المفتوح', 'Open-time end request'),
    _ => _t('تحديث بشأن طلب', 'Request update'),
  };

  String _promptStatusLabel(String? status) => switch (status) {
    'actionable' => _t('يحتاج إلى مراجعتك', 'Needs your review'),
    'pending' => _t('قيد الانتظار', 'Pending'),
    'active' => _t('قيد المعالجة', 'Active'),
    'needs_response' => _t(
      'بانتظار تحديث الصلاحية',
      'Awaiting permission update',
    ),
    'expired' => _t('انتهت المهلة', 'Expired'),
    'handled' => _t('تمت المعالجة', 'Already handled'),
    'completed' => _t('مكتمل', 'Completed'),
    'unavailable' => _t('غير متاح', 'Unavailable'),
    _ => _t('الحالة غير مؤكدة', 'Status unavailable'),
  };

  bool _readyTarget(NotificationView item) =>
      item.targetState == NotificationTargetState.ready && item.target != null;

  bool _actionablePrompt(NotificationView item) {
    final target = item.target;
    return item.promptKind != null &&
        const {
          'extension_request',
          'schedule_change',
          'price_adjustment',
          'completion_decision',
          'open_time_end',
        }.contains(item.promptKind) &&
        item.promptStatus == 'actionable' &&
        _readyTarget(item) &&
        target!.scope != null &&
        (target.destination == WorkerDestination.mission ||
            target.destination == WorkerDestination.visitScope);
  }

  // A configured contact is still external input. Normalize only supported
  // channel/URI shapes before passing them to S00's own validating launcher.
  // This is not origin verification and cannot make a host launcher trusted.
  SupportContactView? _approvedContact(SupportContactView contact) {
    final value = contact.value.trim();
    if (value.isEmpty ||
        value.length > 256 ||
        value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      return null;
    }
    final kind = _contactKind(contact.channel);
    if (kind == null) return null;

    String? phoneNumber(String input) {
      final number = input.toLowerCase().startsWith('tel:')
          ? input.substring(4)
          : input;
      final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
      return digits.length >= 5 &&
              digits.length <= 15 &&
              RegExp(r'^\+?[0-9 ()-]+$').hasMatch(number)
          ? number
          : null;
    }

    Uri? webUri() {
      // Do not accept URL userinfo, backslashes, whitespace, raw numeric IPs,
      // local names or non-HTTPS schemes from remote configuration.
      if (value.contains(RegExp(r'[\s\\]')) ||
          RegExp(r'%(?![0-9A-Fa-f]{2})').hasMatch(value)) {
        return null;
      }
      final uri = Uri.tryParse(value);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          uri.host.isEmpty ||
          uri.host.toLowerCase() == 'localhost' ||
          uri.host.toLowerCase().endsWith('.local') ||
          RegExp(r'^[0-9.]+$').hasMatch(uri.host) ||
          !RegExp(
            r'^(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+'
            r'[A-Za-z][A-Za-z0-9-]{1,62}$',
          ).hasMatch(uri.host)) {
        return null;
      }
      return uri;
    }

    String? destination;
    switch (kind) {
      case 'phone':
        destination = phoneNumber(value);
      case 'email':
        final email = value.toLowerCase().startsWith('mailto:')
            ? value.substring(7)
            : value;
        if (RegExp(
          r'^[A-Za-z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$',
        ).hasMatch(email)) {
          destination = email;
        }
      case 'website':
        if (webUri() != null) destination = value;
      case 'whatsapp':
        destination = phoneNumber(value);
        if (destination == null) {
          final uri = webUri();
          if (uri != null &&
              const {
                'wa.me',
                'api.whatsapp.com',
                'www.whatsapp.com',
              }.contains(uri.host.toLowerCase())) {
            destination = value;
          }
        }
    }
    return destination == null
        ? null
        : SupportContactView(
            label: contact.label,
            channel: kind,
            value: destination,
          );
  }

  bool _safeContact(SupportContactView contact) =>
      _approvedContact(contact) != null;

  Future<void> _launch(SupportContactView channel) async {
    final approved = _approvedContact(channel);
    if (widget.onOpenContact == null || approved == null || !_validSession) {
      return;
    }
    final sourceEpoch = _epoch;
    bool opened;
    try {
      opened = await widget.onOpenContact!(approved);
    } catch (_) {
      opened = false;
    }
    if (mounted && _validSession && sourceEpoch == _epoch) {
      setState(
        () => _message = opened
            ? _t(
                'تم فتح تطبيق الاتصال، ولم يتم تأكيد إجراء المكالمة.',
                'The contact app opened; a connected call is not confirmed.',
              )
            : _t('تعذر فتح قناة الاتصال', 'Could not open the contact app'),
      );
    }
  }

  bool get _validSession {
    final ctx = widget.runtime.context;
    return ctx != null &&
        widget.runtime.phase == RuntimePhase.signedIn &&
        ctx.userId == widget.session.userId &&
        ctx.workerId == widget.session.workerId &&
        ctx.generation == widget.session.generation;
  }

  bool get _online => widget.runtime.connection == ConnectionState.online;
  bool get _freshNotifications {
    final result = _result;
    return widget.destination == WorkerDestination.notifications &&
        result is ReadSuccess<Object> &&
        result.freshness == ReadFreshness.fresh;
  }

  @override
  void initState() {
    super.initState();
    _observeInvalidations();
    _refresh();
  }

  void _observeInvalidations() {
    _invalidationSubscription?.cancel();
    _invalidationSubscription = widget.runtime.invalidations.listen((event) {
      if (!mounted ||
          !_validSession ||
          event.generation != widget.session.generation) {
        return;
      }
      if (widget.destination == WorkerDestination.notifications &&
          event.topic == InvalidationTopic.notifications &&
          !_busy) {
        _refresh();
      }
    });
  }

  @override
  void didUpdateWidget(covariant WorkerCommunicationsModule old) {
    super.didUpdateWidget(old);
    if (old.session.userId != widget.session.userId ||
        old.session.workerId != widget.session.workerId ||
        old.session.generation != widget.session.generation ||
        old.destination != widget.destination ||
        old.scope?.cacheKey != widget.scope?.cacheKey ||
        old.sosAuthorized != widget.sosAuthorized ||
        !listEquals(old.allowedSosReasons, widget.allowedSosReasons) ||
        old.runtime != widget.runtime) {
      _epoch++;
      _result = null;
      _unknown = false;
      _busy = false;
      _reason = null;
      _sosMessage.clear();
      _page = 1;
      if (old.runtime != widget.runtime) _observeInvalidations();
      _refresh();
    }
  }

  @override
  void dispose() {
    _epoch++;
    _invalidationSubscription?.cancel();
    _sosMessage.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    // A read may not cancel a pending notification command by advancing its
    // epoch. Otherwise the command result is discarded and `_busy` stays true.
    if (_busy) return;
    final epoch = ++_epoch;
    setState(() {
      _loading = true;
      _result = null;
      _message = null;
    });
    if (!_validSession) {
      if (mounted && epoch == _epoch) setState(() => _loading = false);
      return;
    }
    if (widget.destination == WorkerDestination.sos) {
      if (mounted && epoch == _epoch) setState(() => _loading = false);
      return;
    }
    ReadResult<Object> r;
    try {
      if (widget.destination == WorkerDestination.support) {
        r = await widget.communications.fetchSupportContacts();
      } else {
        r = await widget.communications.fetchNotifications(
          NotificationQuery(
            unreadOnly: _unreadOnly,
            page: PageQuery(page: _page),
          ),
        );
      }
    } catch (_) {
      r = ReadFailure<Object>(
        PortFailure(kind: FailureKind.server, reasonCode: 'read_unavailable'),
      );
    }
    if (!mounted || epoch != _epoch || !_validSession) return;
    setState(() {
      _result = r;
      _loading = false;
    });
  }

  Future<void> _notificationAction(
    NotificationView item, {
    required bool delete,
  }) async {
    if (_busy ||
        _unknown ||
        !_validSession ||
        !_online ||
        !_freshNotifications) {
      return;
    }
    final beforeConfirmation = _epoch;
    if (delete) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_t('حذف الإشعار؟', 'Delete notification?')),
          content: Text(item.title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_t('إلغاء', 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_t('حذف', 'Delete')),
            ),
          ],
        ),
      );
      if (confirm != true ||
          !mounted ||
          !_validSession ||
          !_online ||
          !_freshNotifications ||
          beforeConfirmation != _epoch) {
        return;
      }
    }
    final epoch = ++_epoch;
    setState(() {
      _busy = true;
      _message = null;
    });
    CommandResult outcome;
    try {
      outcome = delete
          ? await widget.communications.deleteNotification(item.id)
          : await widget.communications.markNotificationRead(item.id);
    } catch (_) {
      outcome = CommandResult(status: CommandStatus.outcomeUnknown);
    }
    if (!mounted || epoch != _epoch || !_validSession) return;
    setState(() {
      _busy = false;
      if (outcome.status == CommandStatus.outcomeUnknown) {
        _unknown = true;
        _message = _t(
          'نتيجة العملية غير مؤكدة. حدّث القائمة للتحقق.',
          'Operation unconfirmed. Refresh the list to verify.',
        );
      } else if (outcome.status == CommandStatus.rejected) {
        _message = _t('تعذر تنفيذ العملية', 'The operation was rejected');
      }
    });
    if (outcome.status == CommandStatus.confirmed) await _refresh();
  }

  Future<void> _sendSos() async {
    if (_busy ||
        _unknown ||
        !_online ||
        !_validSession ||
        widget.scope == null ||
        !widget.sosAuthorized ||
        !widget.allowedSosReasons.contains(_reason)) {
      return;
    }
    final confirmedScope = widget.scope!;
    final confirmedReason = _reason!;
    final confirmedEpoch = _epoch;
    final confirmedMessage = _sosMessage.text.trim();
    if (confirmedMessage.length > 1000) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('إرسال بلاغ طارئ؟', 'Send emergency alert?')),
        content: Text(
          '${_t('الطلب', 'Booking')}: ${confirmedScope.bookingId}\n'
          '${_t('الزيارة', 'Visit')}: ${confirmedScope.sessionId ?? _t('غير محدد', 'Not selected')}\n'
          '${_t('نوع البلاغ', 'Category')}: ${widget.localizedReasonLabels[confirmedReason] ?? confirmedReason}\n'
          '${_t('الوصف', 'Description')}: ${confirmedMessage.isEmpty ? _t('لا يوجد', 'None') : confirmedMessage}\n\n'
          '${_t('سيُرسل البلاغ إلى الدعم. الاتصال الهاتفي خطوة منفصلة.', 'The alert will be sent to support. A phone call is separate.')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('إلغاء', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t('إرسال', 'Send')),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        !_validSession ||
        !_online ||
        confirmedEpoch != _epoch ||
        !widget.sosAuthorized ||
        widget.scope?.cacheKey != confirmedScope.cacheKey ||
        !widget.allowedSosReasons.contains(confirmedReason) ||
        _reason != confirmedReason ||
        _sosMessage.text.trim() != confirmedMessage) {
      return;
    }
    final epoch = ++_epoch;
    setState(() {
      _busy = true;
      _message = null;
    });
    CommandResult outcome;
    try {
      outcome = await widget.communications.sendSos(
        confirmedScope,
        SosDraft(
          reason: confirmedReason,
          message: confirmedMessage.isEmpty ? null : confirmedMessage,
        ),
      );
    } catch (_) {
      outcome = CommandResult(status: CommandStatus.outcomeUnknown);
    }
    if (!mounted || epoch != _epoch || !_validSession) return;
    setState(() {
      _busy = false;
      if (outcome.status == CommandStatus.confirmed) {
        _unknown = true; // No duplicate submission after a confirmed alert.
        _message = _t(
          'تم تأكيد إرسال البلاغ إلى الدعم.',
          'Support confirmed receipt of the alert.',
        );
      } else if (outcome.status == CommandStatus.outcomeUnknown) {
        _unknown = true;
        _message = _t(
          'لم نتأكد من وصول البلاغ. لا ترسله مرة ثانية قبل التحقق.',
          'Delivery could not be confirmed. Do not resend before verifying.',
        );
      } else {
        _message = _t(
          'تعذر إرسال البلاغ. يمكنك استخدام قنوات الدعم المعتمدة.',
          'Alert was rejected. You can use verified support channels.',
        );
      }
    });
  }

  void _open(NotificationView item) {
    if (!_validSession ||
        !_online ||
        !_freshNotifications ||
        _busy ||
        !_readyTarget(item) ||
        (item.promptKind != null && !_actionablePrompt(item))) {
      setState(
        () => _message = _t('الوجهة لم تعد متاحة', 'Destination unavailable'),
      );
      return;
    }
    // Only S00's route handler can authorize and hydrate the selected target.
    final target = item.target!;
    widget.onNavigate(
      RouteIntent(
        destination: target.destination,
        origin: RouteOrigin.notification,
        scope: target.scope,
        entityId: target.entityId,
        jobsStatusFilter: target.jobsStatusFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.destination) {
      WorkerDestination.support => _t('الدعم', 'Support'),
      WorkerDestination.sos => _t('طلب مساعدة طارئة', 'Emergency assistance'),
      _ => _t('الإشعارات', 'Notifications'),
    };
    return WrPageFrame(
      title: title,
      headerAction: widget.destination == WorkerDestination.sos
          ? null
          : WrIconAction(
              icon: Icons.refresh,
              label: _t('تحديث', 'Refresh'),
              onPressed: _busy || _loading
                  ? null
                  : () {
                      _unknown = false;
                      _refresh();
                    },
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_message != null) ...[
            WrEligibilityNotice(
              title: _t('تنبيه', 'Notice'),
              message: _message!,
            ),
            const SizedBox(height: WrSpace.md),
          ],
          if (!_validSession)
            WrFeedbackPanel(
              kind: WrFeedbackKind.forbidden,
              title: _t('يرجى تسجيل الدخول', 'Please sign in'),
            )
          else if (widget.destination == WorkerDestination.sos)
            _sos()
          else if (_loading)
            WrFeedbackPanel(
              kind: WrFeedbackKind.loading,
              title: _t('جاري التحميل', 'Loading'),
            )
          else if (_result is ReadFailure<Object>)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WrFeedbackPanel(
                  kind: WrFeedbackKind.initialError,
                  title: _t('تعذر تحميل البيانات', 'Unable to load'),
                  retryLabel: _t('إعادة المحاولة', 'Retry'),
                  onRetry: _refresh,
                ),
                if (widget.destination == WorkerDestination.support) ...[
                  const SizedBox(height: WrSpace.md),
                  _emergencyPhoneFallback(),
                ],
              ],
            )
          else if (_result is ReadSuccess<Object>)
            widget.destination == WorkerDestination.support
                ? _support((_result as ReadSuccess<Object>).value)
                : _notifications((_result as ReadSuccess<Object>).value)
          else
            WrFeedbackPanel(
              kind: WrFeedbackKind.unavailable,
              title: _t('غير متاح', 'Unavailable'),
            ),
        ],
      ),
    );
  }

  Widget _notifications(Object value) {
    if (value is! Page<NotificationView>) {
      return WrFeedbackPanel(
        kind: WrFeedbackKind.unavailable,
        title: _t('غير متاح', 'Unavailable'),
      );
    }
    return Column(
      children: [
        if (!_online)
          WrEligibilityNotice(
            title: _t('غير متصل', 'Offline'),
            message: _t(
              'القائمة للعرض فقط حتى عودة الاتصال',
              'This list is read-only until connectivity returns',
            ),
          ),
        if (!_freshNotifications)
          WrEligibilityNotice(
            title: _t('البيانات غير محدثة', 'Not current'),
            message: _t(
              'حدّث القائمة أثناء الاتصال للتحقق من صلاحيات الإجراءات.',
              'Refresh online before opening or changing a notification.',
            ),
          ),
        Row(
          children: [
            Expanded(child: Text(_t('غير المقروءة فقط', 'Unread only'))),
            Switch(
              value: _unreadOnly,
              onChanged: _busy || _loading
                  ? null
                  : (value) {
                      _unreadOnly = value;
                      _page = 1;
                      _refresh();
                    },
            ),
          ],
        ),
        if (value.items.isEmpty)
          WrFeedbackPanel(
            kind: WrFeedbackKind.empty,
            title: _unreadOnly
                ? _t('لا توجد إشعارات غير مقروءة', 'No unread notifications')
                : _t('لا توجد إشعارات', 'No notifications'),
          ),
        for (final item in value.items)
          Padding(
            padding: const EdgeInsets.only(bottom: WrSpace.sm),
            child: WrSectionPanel(
              title: item.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _sentAt(item.sentAt),
                    textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
                    style: WrType.support,
                  ),
                  const SizedBox(height: WrSpace.xs),
                  Text(item.body),
                  const SizedBox(height: WrSpace.sm),
                  WrStatusBadge(
                    label: item.isRead
                        ? _t('مقروء', 'Read')
                        : _t('جديد', 'Unread'),
                    tone: item.isRead
                        ? WrStatusTone.neutral
                        : WrStatusTone.info,
                  ),
                  const SizedBox(height: WrSpace.sm),
                  if (item.promptKind != null) ...[
                    Semantics(
                      label:
                          '${_promptKindLabel(item.promptKind)}: '
                          '${_promptStatusLabel(item.promptStatus)}',
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _promptKindLabel(item.promptKind),
                              style: WrType.section,
                            ),
                            const SizedBox(height: WrSpace.xs),
                            WrStatusBadge(
                              label: _promptStatusLabel(item.promptStatus),
                              tone: item.promptStatus == 'actionable'
                                  ? WrStatusTone.warning
                                  : WrStatusTone.neutral,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: WrSpace.sm),
                  ],
                  if (item.targetState == NotificationTargetState.pending)
                    WrEligibilityNotice(
                      title: _t('الوجهة قيد التحقق', 'Destination pending'),
                      message: _t(
                        'لم يتم تأكيد وجهة هذا الإشعار. حدّث القائمة لاحقاً.',
                        'The related destination is not verified. Refresh to check again.',
                      ),
                      tone: WrStatusTone.info,
                    )
                  else if (item.targetState ==
                      NotificationTargetState.unavailable)
                    WrEligibilityNotice(
                      title: _t('الوجهة غير متاحة', 'Destination unavailable'),
                      message: _t(
                        'قد يكون الطلب منتهياً أو خارج صلاحياتك. لا يمكن فتحه من هذا الإشعار.',
                        'The related item may have expired or is no longer accessible.',
                      ),
                      tone: WrStatusTone.neutral,
                    )
                  else if (item.promptKind == null || _actionablePrompt(item))
                    WrActionButton(
                      label: item.promptKind == null
                          ? _t('عرض التفاصيل', 'Open related item')
                          : _t('مراجعة الطلب', 'Review request'),
                      onPressed:
                          _validSession &&
                              _online &&
                              _freshNotifications &&
                              !_busy
                          ? () => _open(item)
                          : null,
                      disabledExplanation: _t(
                        'يلزم الاتصال وتحديث الإشعارات',
                        'Connect and refresh notifications first',
                      ),
                    ),
                  if (item.promptKind != null &&
                      !_actionablePrompt(item) &&
                      item.targetState == NotificationTargetState.ready)
                    Text(
                      _t(
                        'لا يوجد إجراء معتمد حالياً. حدّث القائمة للتحقق من الحالة.',
                        'No authorized action is available. Refresh to verify the status.',
                      ),
                      style: WrType.support,
                    ),
                  if (!item.isRead)
                    WrActionButton(
                      label: _t('تحديد كمقروء', 'Mark read'),
                      role: WrActionRole.secondary,
                      onPressed:
                          _online && _freshNotifications && !_busy && !_unknown
                          ? () => _notificationAction(item, delete: false)
                          : null,
                    ),
                  WrActionButton(
                    label: _t('حذف', 'Delete'),
                    role: WrActionRole.destructive,
                    onPressed:
                        _online && _freshNotifications && !_busy && !_unknown
                        ? () => _notificationAction(item, delete: true)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_page > 1)
              TextButton(
                onPressed: _busy || _loading
                    ? null
                    : () {
                        _page--;
                        _refresh();
                      },
                child: Text(_t('السابق', 'Previous')),
              ),
            Text('${value.page} / ${value.lastPage}'),
            if (_page < value.lastPage)
              TextButton(
                onPressed: _busy || _loading
                    ? null
                    : () {
                        _page++;
                        _refresh();
                      },
                child: Text(_t('التالي', 'Next')),
              ),
          ],
        ),
      ],
    );
  }

  Widget _support(Object value) {
    if (value is! List<SupportContactView>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WrFeedbackPanel(
            kind: WrFeedbackKind.unavailable,
            title: _t('غير متاح', 'Unavailable'),
          ),
          const SizedBox(height: WrSpace.md),
          _emergencyPhoneFallback(),
        ],
      );
    }
    final approved = value.where(_safeContact).toList(growable: false);
    if (approved.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WrFeedbackPanel(
            kind: WrFeedbackKind.empty,
            title: _t(
              'لا توجد قنوات دعم مهيأة',
              'No configured support channels',
            ),
          ),
          const SizedBox(height: WrSpace.md),
          _emergencyPhoneFallback(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_online)
          WrEligibilityNotice(
            title: _t('أنت غير متصل', 'Offline'),
            message: _t(
              'لا يمكن إرسال بلاغ عبر التطبيق. يمكنك محاولة فتح قنوات الاتصال المهيأة.',
              'In-app alerts cannot be sent. You can try a configured contact channel.',
            ),
            tone: WrStatusTone.warning,
          ),
        for (final channel in approved)
          Padding(
            padding: const EdgeInsets.only(bottom: WrSpace.md),
            child: WrSectionPanel(
              title: channel.label,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_channelLabel(channel.channel), style: WrType.support),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SelectableText(
                      channel.value,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  const SizedBox(height: WrSpace.sm),
                  WrActionButton(
                    label: _t('فتح القناة', 'Open channel'),
                    role: WrActionRole.secondary,
                    onPressed: widget.onOpenContact == null || !_validSession
                        ? null
                        : () => _launch(channel),
                  ),
                ],
              ),
            ),
          ),
        if (!_online) _emergencyPhoneFallback(),
      ],
    );
  }

  Widget _sos() {
    if (widget.scope == null || !widget.sosAuthorized) {
      // Lack of in-app SOS authority must never hide an already configured
      // emergency dialer. The dialer is a separate user-initiated action.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WrFeedbackPanel(
            kind: WrFeedbackKind.forbidden,
            title: _t(
              'هذه المهمة غير مخولة لإرسال بلاغ',
              'SOS unavailable for this assignment',
            ),
          ),
          const SizedBox(height: WrSpace.md),
          _emergencyPhoneFallback(),
          const SizedBox(height: WrSpace.sm),
          WrActionButton(
            label: _t('قنوات الدعم', 'Support channels'),
            role: WrActionRole.secondary,
            onPressed: () => widget.onNavigate(
              RouteIntent(
                destination: WorkerDestination.support,
                origin: RouteOrigin.mission,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WrEligibilityNotice(
          title: _t('مساعدة طارئة', 'Emergency support'),
          message: _t(
            'البلاغ داخل التطبيق ليس مكالمة هاتفية. لا تُرسل معلومات الموقع دون إذن.',
            'An in-app alert is not a phone call. Location is not sent without permission.',
          ),
          tone: WrStatusTone.warning,
        ),
        const SizedBox(height: WrSpace.md),
        if (widget.allowedSosReasons.isEmpty)
          WrFeedbackPanel(
            kind: WrFeedbackKind.unavailable,
            title: _t('أنواع البلاغ غير مهيأة', 'Alert categories unavailable'),
          )
        else ...[
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: InputDecoration(
              labelText: _t('نوع الحالة', 'Emergency type'),
            ),
            items: [
              for (final code in widget.allowedSosReasons)
                DropdownMenuItem(
                  value: code,
                  child: Text(widget.localizedReasonLabels[code] ?? code),
                ),
            ],
            onChanged: _busy || _unknown
                ? null
                : (value) => setState(() => _reason = value),
          ),
          const SizedBox(height: WrSpace.sm),
          TextField(
            controller: _sosMessage,
            maxLines: 3,
            maxLength: 1000,
            enabled: !_busy && !_unknown,
            decoration: InputDecoration(
              labelText: _t(
                'تفاصيل إضافية (اختياري)',
                'Additional details (optional)',
              ),
            ),
          ),
          WrActionButton(
            label: _t('إرسال البلاغ', 'Send alert'),
            busy: _busy,
            busyLabel: _t('جاري إرسال البلاغ', 'Sending alert'),
            role: WrActionRole.destructive,
            onPressed:
                _online &&
                    !_busy &&
                    !_unknown &&
                    widget.allowedSosReasons.contains(_reason)
                ? _sendSos
                : null,
          ),
        ],
        const SizedBox(height: WrSpace.sm),
        WrActionButton(
          label: _t('قنوات الدعم', 'Support channels'),
          role: WrActionRole.secondary,
          onPressed: () => widget.onNavigate(
            RouteIntent(
              destination: WorkerDestination.support,
              origin: RouteOrigin.mission,
              scope: widget.scope,
            ),
          ),
        ),
        _emergencyPhoneFallback(),
        if (!_online)
          WrFeedbackPanel(
            kind: WrFeedbackKind.offline,
            title: _t(
              'لا يمكن تأكيد البلاغ دون اتصال',
              'Alert cannot be confirmed while offline',
            ),
          ),
      ],
    );
  }

  Widget _emergencyPhoneFallback() {
    if (_contactKind(widget.verifiedEmergencyPhone?.channel ?? '') == 'phone' &&
        _safeContact(widget.verifiedEmergencyPhone!) &&
        widget.onOpenContact != null) {
      return WrActionButton(
        label: _t(
          'فتح الاتصال الهاتفي بالطوارئ',
          'Open emergency phone dialer',
        ),
        role: WrActionRole.secondary,
        onPressed: () => _launch(widget.verifiedEmergencyPhone!),
      );
    }
    return Text(
      _t(
        'لا يوجد رقم طوارئ مهيأ حالياً. يمكنك مراجعة قنوات الدعم.',
        'No emergency phone number is configured. You can review support channels.',
      ),
    );
  }
}
