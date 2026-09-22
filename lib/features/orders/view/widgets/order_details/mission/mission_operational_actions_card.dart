import 'dart:async';

import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/cleaning_booking_operational_details.dart';
import '../../../../data/models/cleaning_schedule_change_request_model.dart';
import '../../../../data/source/orders_remote_data_source.dart';

class MissionOperationalActionsCard extends StatefulWidget {
  const MissionOperationalActionsCard({
    required this.bookingId,
    required this.openTime,
    required this.materialKit,
    required this.services,
    this.loadScheduleChanges,
    super.key,
  });

  final int bookingId;
  final CleaningOpenTimeDetails? openTime;
  final CleaningMaterialKitDetails? materialKit;
  final List<CleaningSpecialServiceLine> services;
  final Future<List<CleaningScheduleChangeRequestModel>> Function()?
  loadScheduleChanges;

  @override
  State<MissionOperationalActionsCard> createState() =>
      _MissionOperationalActionsCardState();
}

class _MissionOperationalActionsCardState
    extends State<MissionOperationalActionsCard> {
  late CleaningOpenTimeDetails? _openTime;
  late CleaningMaterialKitDetails? _kit;
  late List<CleaningSpecialServiceLine> _services;
  Timer? _ticker;
  bool _busy = false;
  bool _loadingScheduleChanges = true;
  String? _error;
  final Set<int> _resolvedReservationIds = <int>{};
  List<CleaningScheduleChangeRequestModel> _scheduleChanges =
      const <CleaningScheduleChangeRequestModel>[];

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _openTime?.ceilingEndsAt != null) setState(() {});
    });
    unawaited(_loadScheduleChanges());
  }

  @override
  void didUpdateWidget(covariant MissionOperationalActionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy) _syncFromWidget();
    if (oldWidget.bookingId != widget.bookingId) {
      unawaited(_loadScheduleChanges());
    }
  }

  void _syncFromWidget() {
    _openTime = widget.openTime;
    _kit = widget.materialKit;
    _services = List<CleaningSpecialServiceLine>.of(widget.services);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _hasActions {
    return _loadingScheduleChanges ||
        _error != null ||
        _scheduleChanges.isNotEmpty ||
        _openTime?.pendingExtension?.status == 'pending' ||
        _openTime?.endStatus == 'pending' ||
        _kit?.status == 'ready' ||
        _services.any(
          (service) =>
              !const <String>[
                'completed',
                'unable',
              ].contains(service.executionStatus) ||
              service.equipmentReservations.any(
                (reservation) => const <String>[
                  'reserved',
                  'handed_over',
                  'acknowledged',
                ].contains(reservation.status),
              ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActions) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'إجراءات المهمة التشغيلية',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'إجراءات مطلوبة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              _Message(message: _error!, isError: true),
            ],
            if (_loadingScheduleChanges) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'جاري تحميل طلبات تعديل المواعيد',
                child: const LinearProgressIndicator(minHeight: 3),
              ),
            ],
            for (final change in _scheduleChanges) ...[
              const SizedBox(height: 14),
              _DecisionTile(
                icon: Icons.edit_calendar_outlined,
                title: 'طلب تعديل مواعيد الحجز الدوري',
                subtitle: _scheduleChangeSummary(change),
                enabled: !_busy,
                onAccept: () => _decideScheduleChange(change, 'accepted'),
                onReject: () => _decideScheduleChange(change, 'rejected'),
              ),
            ],
            if (_openTime?.pendingExtension?.status == 'pending') ...[
              const SizedBox(height: 14),
              _DecisionTile(
                icon: Icons.more_time_outlined,
                title: 'طلب تمديد الوقت',
                subtitle:
                    '${_openTime!.pendingExtension!.requestedMinutes ?? 0} دقيقة إضافية',
                enabled: !_busy,
                onAccept: () => _decideExtension('accepted'),
                onReject: () => _decideExtension('rejected'),
              ),
            ],
            if (_openTime?.endStatus == 'pending') ...[
              const SizedBox(height: 14),
              _DecisionTile(
                icon: Icons.stop_circle_outlined,
                title: 'طلب العميل إنهاء الخدمة',
                subtitle: 'راجع إنجاز المهمة ثم اختر قراراً واضحاً.',
                enabled: !_busy,
                onAccept: () => _decideEnd('accepted'),
                onReject: () => _decideEnd('rejected'),
              ),
            ],
            if (_kit?.status == 'ready') ...[
              const SizedBox(height: 14),
              _ActionTile(
                icon: Icons.inventory_2_outlined,
                title: 'طقم مواد التنظيف جاهز',
                subtitle: 'أكد الاستلام قبل بدء استخدام المواد.',
                actionLabel: 'تأكيد الاستلام',
                enabled: !_busy,
                onPressed: _receiveKit,
              ),
            ],
            for (final service in _services) ...[
              if (!const <String>[
                'completed',
                'unable',
              ].contains(service.executionStatus)) ...[
                const SizedBox(height: 14),
                _ServiceActions(
                  service: service,
                  enabled: !_busy,
                  onStart: () => _startService(service),
                  onComplete: () => _finishService(service, 'completed'),
                  onUnable: () => _finishService(service, 'unable'),
                  onAcknowledge: _acknowledgeEquipment,
                  onReturn: _returnEquipment,
                  resolvedReservationIds: _resolvedReservationIds,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _decideExtension(String decision) async {
    final extensionId = _openTime?.pendingExtension?.id;
    if (extensionId == null) return;
    final reason = decision == 'rejected'
        ? await _reasonDialog('سبب رفض التمديد')
        : null;
    if (decision == 'rejected' && reason == null) return;
    await _run(() async {
      _openTime = await getIt<OrdersRemoteDataSource>().decideOpenTimeExtension(
        extensionId: extensionId,
        decision: decision,
        reason: reason,
      );
    });
  }

  Future<void> _loadScheduleChanges() async {
    if (mounted) {
      setState(() {
        _loadingScheduleChanges = true;
        _error = null;
      });
    }
    try {
      final loader = widget.loadScheduleChanges;
      final all = loader != null
          ? await loader()
          : await getIt<OrdersRemoteDataSource>()
                .fetchPendingScheduleChangeRequests();
      if (!mounted) return;
      setState(() {
        _scheduleChanges = all
            .where((item) => item.bookingId == widget.bookingId)
            .toList(growable: false);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل طلبات تعديل المواعيد. حاول مرة أخرى.';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingScheduleChanges = false);
    }
  }

  String _scheduleChangeSummary(CleaningScheduleChangeRequestModel change) {
    if (change.sessions.isEmpty) {
      return change.priceDelta == 0
          ? 'راجع التعديل المقترح قبل اتخاذ القرار.'
          : 'فرق السعر: ${change.priceDelta.toStringAsFixed(0)}';
    }
    final slots = change.sessions
        .take(3)
        .map((session) => '${session.date} • ${session.time}');
    final remaining = change.sessions.length - 3;
    return <String>[
      slots.join('، '),
      if (remaining > 0) 'و$remaining مواعيد أخرى',
      if (change.priceDelta != 0)
        'فرق السعر: ${change.priceDelta.toStringAsFixed(0)}',
    ].join('\n');
  }

  Future<void> _decideScheduleChange(
    CleaningScheduleChangeRequestModel change,
    String decision,
  ) async {
    final reason = decision == 'rejected'
        ? await _reasonDialog('سبب رفض تعديل المواعيد')
        : null;
    if (decision == 'rejected' && reason == null) return;
    await _run(() async {
      await getIt<OrdersRemoteDataSource>().decideScheduleChange(
        changeRequestId: change.id,
        decision: decision,
        reason: reason,
      );
      _scheduleChanges = _scheduleChanges
          .where((item) => item.id != change.id)
          .toList(growable: false);
    });
  }

  Future<void> _decideEnd(String decision) async {
    final reason = decision == 'rejected'
        ? await _reasonDialog('سبب رفض الإنهاء')
        : null;
    if (decision == 'rejected' && reason == null) return;
    await _run(() async {
      _openTime = await getIt<OrdersRemoteDataSource>().decideOpenTimeEnd(
        bookingId: widget.bookingId,
        decision: decision,
        reason: reason,
      );
    });
  }

  Future<void> _receiveKit() async {
    await _run(() async {
      final result = await getIt<OrdersRemoteDataSource>().receiveMaterialKit(
        widget.bookingId,
      );
      _kit = result.materialKit ?? _kit;
    });
  }

  Future<void> _startService(CleaningSpecialServiceLine service) async {
    if (service.id == null) return;
    await _run(() async {
      final result = await getIt<OrdersRemoteDataSource>().startSpecialService(
        service.id!,
      );
      _replaceService(result.specialService);
    });
  }

  Future<void> _finishService(
    CleaningSpecialServiceLine service,
    String status,
  ) async {
    if (service.id == null) return;
    final reason = status == 'unable'
        ? await _reasonDialog('سبب تعذر تنفيذ الخدمة')
        : null;
    if (status == 'unable' && reason == null) return;
    await _run(() async {
      final result = await getIt<OrdersRemoteDataSource>().finishSpecialService(
        lineId: service.id!,
        status: status,
        reason: reason,
      );
      _replaceService(result.specialService);
    });
  }

  Future<void> _acknowledgeEquipment(
    CleaningEquipmentReservationDetails reservation,
  ) async {
    if (reservation.id == null) return;
    await _run(() async {
      await getIt<OrdersRemoteDataSource>().acknowledgeEquipment(
        reservation.id!,
      );
      _resolvedReservationIds.add(reservation.id!);
    });
  }

  Future<void> _returnEquipment(
    CleaningEquipmentReservationDetails reservation,
  ) async {
    if (reservation.id == null) return;
    final failed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حالة إرجاع المعدة'),
        content: const Text('هل أُعيدت المعدة بحالة سليمة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('رجوع'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('يوجد عطل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('سليمة'),
          ),
        ],
      ),
    );
    if (failed == null || !mounted) return;
    final reason = failed ? await _reasonDialog('وصف العطل') : null;
    if (failed && reason == null) return;
    await _run(() async {
      await getIt<OrdersRemoteDataSource>().returnEquipment(
        reservationId: reservation.id!,
        failureReason: reason,
      );
      _resolvedReservationIds.add(reservation.id!);
    });
  }

  void _replaceService(CleaningSpecialServiceLine? updated) {
    if (updated?.id == null) return;
    final index = _services.indexWhere((item) => item.id == updated!.id);
    if (index >= 0) _services[index] = updated!;
  }

  Future<String?> _reasonDialog(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'السبب',
            helperText: 'اكتب سبباً واضحاً ليظهر في سجل الطلب.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث المهمة بنجاح.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تنفيذ الإجراء. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onAccept,
    required this.onReject,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return _ActionShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: enabled ? onReject : null,
                child: const Text('رفض'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: enabled ? onAccept : null,
                child: const Text('موافقة'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          child: Text(actionLabel),
        ),
      ),
    );
  }
}

class _ServiceActions extends StatelessWidget {
  const _ServiceActions({
    required this.service,
    required this.enabled,
    required this.onStart,
    required this.onComplete,
    required this.onUnable,
    required this.onAcknowledge,
    required this.onReturn,
    required this.resolvedReservationIds,
  });

  final CleaningSpecialServiceLine service;
  final bool enabled;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onUnable;
  final ValueChanged<CleaningEquipmentReservationDetails> onAcknowledge;
  final ValueChanged<CleaningEquipmentReservationDetails> onReturn;
  final Set<int> resolvedReservationIds;

  @override
  Widget build(BuildContext context) {
    final inProgress = service.executionStatus == 'in_progress';
    return _ActionShell(
      icon: Icons.cleaning_services_outlined,
      title: service.name ?? 'خدمة خاصة',
      subtitle: inProgress ? 'قيد التنفيذ' : 'بانتظار البدء',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!inProgress)
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: enabled ? onStart : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('بدء الخدمة'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: enabled ? onUnable : null,
                      child: const Text('تعذر التنفيذ'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: enabled ? onComplete : null,
                      child: const Text('تم التنفيذ'),
                    ),
                  ),
                ),
              ],
            ),
          for (final reservation in service.equipmentReservations) ...[
            if (reservation.id != null &&
                resolvedReservationIds.contains(reservation.id))
              const SizedBox.shrink()
            else ...[
              const SizedBox(height: 8),
              if (const <String>[
                'reserved',
                'handed_over',
              ].contains(reservation.status))
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: enabled
                        ? () => onAcknowledge(reservation)
                        : null,
                    icon: const Icon(Icons.handyman_outlined),
                    label: Text('استلام ${reservation.name ?? 'المعدة'}'),
                  ),
                )
              else if (reservation.status == 'acknowledged')
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: enabled ? () => onReturn(reservation) : null,
                    icon: const Icon(Icons.assignment_return_outlined),
                    label: Text('إرجاع ${reservation.name ?? 'المعدة'}'),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ActionShell extends StatelessWidget {
  const _ActionShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : const Color(0xFF166534);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
