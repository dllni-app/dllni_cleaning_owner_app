import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_operational_details.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/worker_session_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/orders_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_enum_translations.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/event_assistance_order_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_address_visibility_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_details_to_list_item_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/property_attribute_labels_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/worker_payment_summary.dart';
import 'order_details/worker_order_overview_card.dart';
import 'order_details/worker_detail_section.dart';
import 'package:flutter/material.dart';
import 'worker_action_terms_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _borderColor = Color(0xffE5E7EB);
const _mutedTextColor = Color(0xff6B7280);
const _titleTextColor = Color(0xff111827);

class _AcceptOrderSheetResult {
  const _AcceptOrderSheetResult({
    required this.accepted,
    this.selectedSessionId,
  });

  final bool accepted;
  final int? selectedSessionId;
}

class AcceptOrderBottomSheet extends StatefulWidget {
  const AcceptOrderBottomSheet({
    super.key,
    required this.order,
    required this.bloc,
    required this.index,
    this.autoRejectOnClose = false,
    this.useRootNavigator = false,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final OrdersBloc bloc;
  final int index;
  final bool autoRejectOnClose;
  final bool useRootNavigator;

  static Future<void> show(
    BuildContext context, {
    required FetchOrdersUsecaseModelDataItem order,
    required OrdersBloc bloc,
    required int index,
    bool autoRejectOnClose = false,
    bool useRootNavigator = false,
    ValueChanged<int?>? onAccepted,
  }) async {
    if (!OrderLifecyclePolicy.canAcceptReject(order)) {
      final bookingId = order.id;
      bool hasAvailableVisits = false;
      if (bookingId != null) {
        try {
          final envelope = await getIt<WorkerSessionRemoteDataSource>()
              .fetchBookingSchedule(bookingId);
          hasAvailableVisits =
              envelope.schedule?.sessions.any(
                (session) => session.id != null && !session.isTerminal,
              ) ??
              false;
        } catch (_) {
          // Preserve the legacy parent gate when the schedule cannot be checked.
        }
      }
      if (!hasAvailableVisits) {
        AppToast.showErrorGlobal(
          OrderLifecyclePolicy.orderNoLongerAvailableMessage,
        );
        return;
      }
    }
    if (!context.mounted) return;

    final closeAction = await showModalBottomSheet<_AcceptOrderSheetResult>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AcceptOrderBottomSheet(
        order: order,
        bloc: bloc,
        index: index,
        autoRejectOnClose: autoRejectOnClose,
        useRootNavigator: useRootNavigator,
      ),
    );

    if (closeAction?.accepted == true) {
      onAccepted?.call(closeAction?.selectedSessionId);
      return;
    }
    // Closing a visit offer is not an explicit rejection.
  }

  @override
  State<AcceptOrderBottomSheet> createState() => _AcceptOrderBottomSheetState();
}

class _AcceptOrderBottomSheetState extends State<AcceptOrderBottomSheet> {
  FetchOrdersUsecaseModelDataItem? _detailedOrder;

  FetchOrdersUsecaseModelDataItem get _order => _detailedOrder ?? widget.order;

  WorkerBookingScheduleModel? _schedule;
  bool _scheduleChecked = false;
  bool _scheduleLoading = false;
  bool _detailsChecked = false;
  bool _detailsLoading = false;
  bool _sessionAcceptanceLoading = false;
  int? _lastAcceptedSessionId;
  String? _scheduleError;
  String? _detailsError;

  bool get _isEventAssistance =>
      EventAssistanceOrderHelper.isEventAssistance(_order.propertyType);

  bool get _isHourlyWorker => _order.isHourlyWorker;

  bool get _isMultiSession => _schedule?.isMultiDay == true;

  bool get _canConfirmAcceptance =>
      _scheduleChecked &&
      !_scheduleLoading &&
      _scheduleError == null &&
      // A signed single-visit booking may be readable but have no eligible
      // execution session. Never fall back to the parent accept endpoint.
      !((_schedule?.bookingDaysCount ?? 0) > 0 &&
          _schedule?.hasPersistedSessions != true) &&
      _detailsChecked &&
      !_detailsLoading &&
      _detailsError == null;

  @override
  void initState() {
    super.initState();
    if (_order.id != null) {
      unawaited(_loadOrderDetails());
      unawaited(_loadSchedule());
    } else {
      _scheduleChecked = true;
      _detailsChecked = true;
    }
  }

  Future<void> _loadOrderDetails() async {
    final orderId = widget.order.id;
    if (orderId == null || _detailsLoading) return;

    setState(() {
      _detailsLoading = true;
      _detailsError = null;
    });

    try {
      final result = await getIt<OrdersRemoteDataSource>()
          .fetchOrderDetailsUsecase(
            FetchOrderDetailsUsecaseParams(id: orderId),
          );
      final details = result.data;
      if (!mounted) return;
      if (details == null) {
        setState(() {
          _detailsChecked = true;
          _detailsLoading = false;
          _detailsError =
              'تعذر تحميل تفاصيل الطلب الكاملة. أعد المحاولة قبل القبول.';
        });
        return;
      }

      setState(() {
        _detailedOrder = OrderDetailsToListItemMapper.fromDetails(
          details,
          fallback: widget.order,
        );
        _detailsChecked = true;
        _detailsLoading = false;
        _detailsError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detailsChecked = true;
        _detailsLoading = false;
        _detailsError =
            'تعذر تحميل تفاصيل الطلب الكاملة. أعد المحاولة قبل القبول.';
      });
    }
  }

  Future<void> _loadSchedule() async {
    final orderId = _order.id;
    if (orderId == null || _scheduleLoading) return;
    setState(() {
      _scheduleLoading = true;
      _scheduleError = null;
    });
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .fetchBookingSchedule(orderId);
      if (!mounted) return;
      setState(() {
        _schedule = result.schedule;
        _scheduleChecked = true;
        _scheduleLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scheduleChecked = true;
        _scheduleLoading = false;
        _scheduleError = 'تعذر تحميل جدول الزيارات. أعد المحاولة قبل القبول.';
      });
    }
  }

  void _refreshAfterSessionAcceptance(int bookingId) {
    widget.bloc.add(
      SyncOrderFromRealtimeEvent(
        bookingId: bookingId,
        sessionAcceptanceSucceeded: true,
      ),
    );
  }

  String _sessionAcceptanceFailureMessage({
    required WorkerSessionAcceptanceResult result,
    required String fallback,
  }) {
    if (result.rejected.isNotEmpty) {
      return ErrorMessageFormatter.format(
        result.rejected.first.message,
        fallback: fallback,
      );
    }

    return ErrorMessageFormatter.format(result.message, fallback: fallback);
  }

  String _sessionAcceptanceExceptionMessage(
    Object error, {
    required String fallback,
  }) {
    try {
      final dynamic dynamicError = error;
      final dynamic responseData = dynamicError.response?.data;
      if (responseData != null) {
        final parsed = WorkerSessionAcceptanceResult.fromJson(responseData);
        if (parsed.rejected.isNotEmpty ||
            (parsed.message?.trim().isNotEmpty ?? false)) {
          return _sessionAcceptanceFailureMessage(
            result: parsed,
            fallback: fallback,
          );
        }
      }
    } catch (_) {
      // Fall back to the normalized exception text below.
    }

    return ErrorMessageFormatter.format(error.toString(), fallback: fallback);
  }

  int? _firstAcceptedSessionId(List<int> acceptedSessionIds) {
    if (acceptedSessionIds.isEmpty) return null;
    final accepted = acceptedSessionIds.toSet();
    final sessions = _schedule?.sessions ?? const <WorkerBookingSessionModel>[];
    for (final session in sessions) {
      final sessionId = session.id;
      if (sessionId != null && accepted.contains(sessionId)) {
        return sessionId;
      }
    }
    return acceptedSessionIds.first;
  }

  Future<void> _showSelectedSessionsPicker() async {
    final schedule = _schedule;
    if (schedule == null || _sessionAcceptanceLoading) return;

    final sessions = schedule.sessions
        .where((session) => session.id != null && !session.isTerminal)
        .toList(growable: false);
    if (sessions.isEmpty) {
      AppToast.showErrorGlobal('لا توجد زيارات متاحة للاختيار حالياً.');
      return;
    }

    final selectedIds = <int>{};
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      useRootNavigator: widget.useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * .78,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.titleMedium(
                                  'حدد الزيارات التي يمكنك قبولها',
                                  fontWeight: FontWeight.w800,
                                ),
                                const SizedBox(height: 4),
                                AppText.bodySmall(
                                  'سيتم حجز الزيارات التي تختارها لك، وتبقى باقي الزيارات متاحة لعمال آخرين.',
                                  color: _mutedTextColor,
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final session = sessions[index];
                          final sessionId = session.id!;
                          final selected = selectedIds.contains(sessionId);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selectedIds.add(sessionId);
                                } else {
                                  selectedIds.remove(sessionId);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _borderColor),
                            ),
                            title: AppText.bodyMedium(
                              '${_sessionSequenceLabel(session)} — ${_sessionDate(session)}',
                              fontWeight: FontWeight.w800,
                              textAlign: TextAlign.start,
                            ),
                            subtitle: AppText.bodySmall(
                              '${_sessionTime(session)} — ${_hours(session.hours)} ساعة',
                              color: _mutedTextColor,
                              textAlign: TextAlign.start,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        12,
                        16,
                        16,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () => Navigator.of(
                                  sheetContext,
                                ).pop(selectedIds.toList(growable: false)),
                          child: Text(
                            selectedIds.isEmpty
                                ? 'اختر زيارة واحدة على الأقل'
                                : 'قبول ${selectedIds.length} زيارة',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null || result.isEmpty) return;
    await _acceptSelectedSessions(result);
  }

  Future<void> _acceptSelectedSessions(List<int> sessionIds) async {
    final bookingId = _order.id;
    if (bookingId == null ||
        _sessionAcceptanceLoading ||
        !_canConfirmAcceptance)
      return;
    final availableIds =
        _schedule?.sessions
            .where((session) => session.id != null && !session.isTerminal)
            .map((session) => session.id)
            .toSet() ??
        <int?>{};
    if (sessionIds.isEmpty ||
        sessionIds.any((id) => !availableIds.contains(id)))
      return;
    if (!await confirmWorkerActionTerms(context, cancelling: false)) return;
    if (!mounted) return;

    setState(() => _sessionAcceptanceLoading = true);
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .acceptSelectedSessions(bookingId: bookingId, sessionIds: sessionIds);
      if (!mounted) return;

      if (result.acceptedSessionIds.isEmpty) {
        final message = _sessionAcceptanceFailureMessage(
          result: result,
          fallback: 'تعذر قبول الزيارات المحددة. راجع جدولك وحاول مجدداً.',
        );
        AppToast.showErrorGlobal(message);
        setState(() => _sessionAcceptanceLoading = false);
        await _loadSchedule();
        return;
      }

      _refreshAfterSessionAcceptance(bookingId);
      final acceptedCount = result.acceptedSessionIds.length;
      final rejectedCount = result.rejected.length;
      AppToast.showSuccessGlobal(
        rejectedCount == 0
            ? 'تم قبول $acceptedCount زيارة'
            : 'تم قبول $acceptedCount زيارة، وتعذر قبول $rejectedCount زيارة',
      );
      _lastAcceptedSessionId = _firstAcceptedSessionId(
        result.acceptedSessionIds,
      );
      if (!_isMultiSession) {
        _dismissSheet();
        return;
      }
      setState(() => _sessionAcceptanceLoading = false);
      await _loadSchedule();
    } catch (error) {
      if (!mounted) return;
      AppToast.showErrorGlobal(
        _sessionAcceptanceExceptionMessage(
          error,
          fallback: 'تعذر قبول الزيارات المحددة. راجع جدولك وحاول مجدداً.',
        ),
      );
      setState(() => _sessionAcceptanceLoading = false);
      await _loadSchedule();
    }
  }

  String _serviceName() {
    if (_order.isHourlyWorker) return 'عامل بالساعة';
    return EventAssistanceOrderHelper.serviceTitle(
      propertyType: _order.propertyType,
      customService: _order.propertyDetails?.customService,
    );
  }

  String _formatDate() {
    return CleaningArabicTimeFormatter.formatScheduledDate(
      _order.scheduledDate,
      includeWeekday: false,
    );
  }

  String _formatWeekday() {
    return CleaningArabicTimeFormatter.formatScheduledWeekday(
      _order.scheduledDate,
    );
  }

  String _formatTime() {
    return CleaningArabicTimeFormatter.formatFromScheduledTimeField(
      _order.scheduledTime,
    );
  }

  String _sessionDate(WorkerBookingSessionModel session) {
    final date = session.date;
    if (date == null) return '-';
    final raw =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return CleaningArabicTimeFormatter.formatScheduledDate(
      raw,
      includeWeekday: true,
    );
  }

  String _sessionTime(WorkerBookingSessionModel session) {
    return CleaningArabicTimeFormatter.formatFromScheduledTimeField(
      session.time,
    );
  }

  String _sessionSequenceLabel(WorkerBookingSessionModel session) {
    if (_isEventAssistance) {
      return 'اليوم ${session.sequence} من ${_schedule?.daysCount ?? 1}';
    }
    if ((_schedule?.daysCount ?? 1) == 1) return 'الزيارة المطلوبة';
    return 'زيارة ${session.sequence}';
  }

  String _hours(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  String _valueOrDash(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return '-';
    return normalized;
  }

  String _bookingCode() {
    final bookingNumber = _order.bookingNumber?.trim();
    if (bookingNumber != null && bookingNumber.isNotEmpty) {
      return bookingNumber;
    }
    final id = _order.id;
    return id == null ? '-' : id.toString();
  }

  void _dismissSheet() {
    Navigator.of(context).pop(
      _AcceptOrderSheetResult(
        accepted: _lastAcceptedSessionId != null,
        selectedSessionId: _lastAcceptedSessionId,
      ),
    );
  }

  Widget _detailCard(BuildContext context, List<Widget> children) {
    return Container(
      width: context.width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _orderInfoRow({
    required String label,
    required String value,
    bool withDivider = true,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppText.bodySmall(
                label,
                color: _mutedTextColor,
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText.bodyMedium(
                value,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        if (withDivider) ...[
          const SizedBox(height: 8),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<Widget> _serviceWidgets() {
    final services = _order.services ?? const [];
    final addons = _order.addons ?? const [];
    final specialServices = _order.specialServices ?? const [];
    final materials = _order.materials ?? const [];
    final openTime = _order.openTime;

    final widgets = <Widget>[];

    if (_isHourlyWorker) {
      final instructions = _order.propertyDetails?.notes?.trim();
      if (instructions != null && instructions.isNotEmpty) {
        widgets.add(
          AppText.bodyMedium(
            instructions,
            textAlign: TextAlign.start,
            color: _titleTextColor,
          ),
        );
      } else {
        widgets.add(const Text('لم يحدد العميل تفاصيل المهام بعد.'));
      }
    }

    if (_isEventAssistance) {
      widgets.add(
        AppText.bodyMedium(
          _serviceName(),
          fontWeight: FontWeight.w700,
          color: _titleTextColor,
        ),
      );
    }

    if (!_isHourlyWorker) {
      widgets.addAll(services.map((s) => _serviceLine(s.name, s.quantity)));
      widgets.addAll(addons.map((a) => _serviceLine(a.name, a.quantity)));
    }

    for (final service in specialServices) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 6));
      }
      widgets.add(_specialServiceCard(service));
    }

    if (materials.isNotEmpty || _order.materialKit != null) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
      widgets.add(
        AppText.bodyMedium(
          'مواد تنظيف مطلوبة مع الخدمة',
          fontWeight: FontWeight.w800,
          color: _titleTextColor,
          textAlign: TextAlign.start,
        ),
      );
      widgets.add(const SizedBox(height: 6));
      widgets.addAll(
        materials.map(
          (material) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: AppText.bodySmall(
                    _valueOrDash(material.name),
                    fontWeight: FontWeight.w700,
                    textAlign: TextAlign.start,
                  ),
                ),
                if (material.quantity != null)
                  AppText.bodySmall(
                    '${_number(material.quantity!)} ${material.unitLabel ?? material.unit ?? ''}'
                        .trim(),
                    color: _mutedTextColor,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (openTime != null && openTime.isOpenTime != false) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
      final details = <String>[];
      if (openTime.requestedWorkerCount != null) {
        details.add('عدد العمال: ${openTime.requestedWorkerCount}');
      }
      if (openTime.expectedMaxMinutes != null) {
        details.add(
          'المدة المتوقعة القصوى: ${_minutesLabel(openTime.expectedMaxMinutes!)}',
        );
      }
      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xffEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xffBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(
                'عامل بالساعة',
                fontWeight: FontWeight.w800,
                color: const Color(0xff1E3A8A),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 4),
                AppText.bodySmall(
                  details.join(' · '),
                  color: const Color(0xff1E3A8A),
                  textAlign: TextAlign.start,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return [
        AppText.bodySmall(
          'لا توجد خدمات أو إضافات أخرى',
          color: _mutedTextColor,
          textAlign: TextAlign.start,
        ),
      ];
    }

    return widgets;
  }

  Widget _specialServiceCard(CleaningSpecialServiceLine service) {
    final details = <String>[];
    final quantity = service.quantity;
    if (quantity != null) {
      final unit = service.pricingUnitLabel ?? service.pricingUnit;
      details.add(
        '${_number(quantity)}${unit == null || unit.trim().isEmpty ? '' : ' $unit'}',
      );
    }
    final dirtiness = service.dirtinessLabel ?? service.dirtinessLevel;
    if (dirtiness != null && dirtiness.trim().isNotEmpty) {
      details.add('درجة الاتساخ: $dirtiness');
    }
    if (service.equipment.isNotEmpty) {
      final names = service.equipment
          .map((item) => item.name?.trim())
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .join('، ');
      if (names.isNotEmpty) details.add('المعدات: $names');
    }

    final itemNotes = service.items
        .map((item) => item.notes?.trim())
        .whereType<String>()
        .where((note) => note.isNotEmpty)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffF0FDFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xff99F6E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(
            _valueOrDash(service.name),
            fontWeight: FontWeight.w800,
            color: _titleTextColor,
            textAlign: TextAlign.start,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            AppText.bodySmall(
              details.join(' · '),
              color: _mutedTextColor,
              textAlign: TextAlign.start,
            ),
          ],
          if (service.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 5),
            AppText.bodySmall(
              'ملاحظة المستخدم: ${service.notes!.trim()}',
              color: _titleTextColor,
              textAlign: TextAlign.start,
            ),
          ],
          ...itemNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AppText.bodySmall(
                'تفصيل إضافي: $note',
                color: _titleTextColor,
                textAlign: TextAlign.start,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _number(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  String _minutesLabel(int minutes) {
    if (minutes % 60 == 0) return '${minutes ~/ 60} ساعة';
    if (minutes > 60) {
      return '${minutes ~/ 60} ساعة و${minutes % 60} دقيقة';
    }
    return '$minutes دقيقة';
  }

  Widget _serviceLine(String? name, int? quantity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: AppText.bodyMedium(
              _valueOrDash(name),
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.start,
              color: _titleTextColor,
            ),
          ),
          AppText.bodySmall('x${quantity ?? 1}', color: _mutedTextColor),
        ],
      ),
    );
  }

  List<Widget> _propertyDetailsRows() {
    if (_isHourlyWorker) {
      final details = _order.propertyDetails;
      final rows = <MapEntry<String, String>>[
        const MapEntry('نوع الطلب', 'عامل بالساعة'),
        if (_order.openTime?.requestedWorkerCount != null)
          MapEntry('عدد العمال', '${_order.openTime!.requestedWorkerCount}'),
        if (_order.openTime?.expectedMaxMinutes != null)
          MapEntry(
            'المدة القصوى المتوقعة',
            _minutesLabel(_order.openTime!.expectedMaxMinutes!),
          ),
        if (details?.notes?.trim().isNotEmpty == true)
          MapEntry('ملاحظات المستخدم', details!.notes!.trim()),
      ];

      return List<Widget>.generate(rows.length, (index) {
        final row = rows[index];
        return _orderInfoRow(
          label: row.key,
          value: row.value,
          withDivider: index != rows.length - 1,
        );
      });
    }

    if (_isEventAssistance) {
      final details = _order.propertyDetails;
      final rows = <MapEntry<String, String>>[
        MapEntry(
          'نوع المناسبة',
          CleaningEnumTranslations.eventType(details?.eventType),
        ),
        MapEntry('الخدمة المطلوبة', _serviceName()),
        if (details?.guestCount != null)
          MapEntry('عدد الضيوف', '${details!.guestCount}'),
        if (details?.venueType?.trim().isNotEmpty == true)
          MapEntry(
            'نوع المكان',
            CleaningEnumTranslations.venueType(details!.venueType),
          ),
        if (details?.hours != null)
          MapEntry('عدد الساعات', '${_number(details!.hours!)} ساعة'),
        if (details?.specialRequirement?.trim().isNotEmpty == true)
          MapEntry('متطلب خاص', details!.specialRequirement!.trim()),
        if (details?.notes?.trim().isNotEmpty == true)
          MapEntry('ملاحظات المستخدم', details!.notes!.trim()),
      ];

      return List<Widget>.generate(rows.length, (index) {
        final row = rows[index];
        return _orderInfoRow(
          label: row.key,
          value: row.value,
          withDivider: index != rows.length - 1,
        );
      });
    }

    final List<Map<String, dynamic>> items = [
      {
        'label': 'عدد غرف المعيشة',
        'value': PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          _order,
          roomType: 'living_room',
        ),
      },
      {
        'label': 'عدد الحمامات',
        'value': PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          _order,
          roomType: 'bathroom',
        ),
      },
      {
        'label': 'عدد المطابخ',
        'value': PropertyAttributeLabelsHelper.kitchenCountForOrder(_order),
      },
      {
        'label': 'عدد الموزع',
        'value': PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          _order,
          roomType: 'hall',
        ),
      },
      {
        'label': 'عدد الممرات',
        'value': PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          _order,
          roomType: 'corridor',
        ),
      },
      {
        'label': 'عدد الشرف',
        'value': PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          _order,
          roomType: 'balcony',
        ),
      },
      {
        'label': 'عدد السقائف',
        'value': PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          _order,
          roomType: 'shed',
        ),
      },
      {
        'label': 'عدد غرف النوم',
        'value': PropertyAttributeLabelsHelper.roomTypeCountForOrder(
          _order,
          roomType: 'bedroom',
        ),
      },
    ];

    final visibleItems = items.where((item) {
      final val = item['value'];
      return val != null && val > 0;
    }).toList();

    final propertyTypeLabel = CleaningEnumTranslations.propertyType(
      _order.propertyType,
    );
    final showPropertyType =
        propertyTypeLabel.trim().isNotEmpty && propertyTypeLabel != 'غير محدد';

    final rows = <Widget>[
      if (showPropertyType)
        _orderInfoRow(
          label: 'نوع المكان',
          value: propertyTypeLabel,
          withDivider: visibleItems.isNotEmpty,
        ),
      ...List.generate(visibleItems.length, (index) {
        final item = visibleItems[index];
        final isLast = index == visibleItems.length - 1;

        return _orderInfoRow(
          label: item['label'],
          value: PropertyAttributeLabelsHelper.formatCount(item['value']),
          withDivider: !isLast,
        );
      }),
    ];

    if (rows.isEmpty) {
      return [
        _orderInfoRow(label: 'نوع المكان', value: '-', withDivider: false),
      ];
    }

    return rows;
  }

  String _preAcceptanceAddressText() {
    final neighborhood = _order.displayNeighborhoodName?.trim();
    if (neighborhood != null && neighborhood.isNotEmpty) {
      return neighborhood;
    }

    final visible = visibleOrderAddress(
      address: _order.propertyDetails?.address ?? _order.locationName,
      status: _order.status,
    ).trim();

    if (visible.isEmpty || visible == '-') {
      return 'الحي غير محدد';
    }
    return visible;
  }

  Widget _scheduleSection(BuildContext context) {
    if (_scheduleLoading) {
      return _detailCard(context, const [
        Center(child: CircularProgressIndicator.adaptive()),
      ]);
    }
    if (_scheduleError != null) {
      return _detailCard(context, [
        AppText.bodySmall(
          _scheduleError!,
          color: context.error,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _scheduleLoading ? null : _loadSchedule,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة تحميل الزيارات'),
        ),
      ]);
    }
    final schedule = _schedule;
    if (schedule == null || !schedule.isMultiDay) {
      return _detailCard(context, [
        _orderInfoRow(label: 'يوم الخدمة', value: _formatWeekday()),
        _orderInfoRow(label: 'التاريخ', value: _formatDate()),
        _orderInfoRow(label: 'الوقت', value: _formatTime(), withDivider: false),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailCard(context, [
          _orderInfoRow(
            label: _isEventAssistance ? 'عدد الأيام' : 'عدد الزيارات',
            value: '${schedule.daysCount}',
          ),
          _orderInfoRow(
            label: 'إجمالي الساعات',
            value: '${_hours(schedule.totalHours)} ساعة',
            withDivider: false,
          ),
        ]),
        const SizedBox(height: 10),
        ...schedule.sessions.map(
          (session) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    _sessionSequenceLabel(session),
                    fontWeight: FontWeight.w800,
                    color: _titleTextColor,
                  ),
                  const SizedBox(height: 5),
                  AppText.bodySmall(
                    _sessionDate(session),
                    color: _mutedTextColor,
                  ),
                  const SizedBox(height: 3),
                  AppText.bodySmall(
                    '${_sessionTime(session)} — ${_hours(session.hours)} ساعة',
                    fontWeight: FontWeight.w700,
                    color: _titleTextColor,
                  ),
                  if (session.pricingPreview?.workerAmount != null ||
                      session.financial?.netAmount != null ||
                      session.workerAssignmentState?.workerAmount != null) ...[
                    const SizedBox(height: 6),
                    AppText.bodyMedium(
                      '${session.pricingPreview != null ? 'مستحق هذه الزيارة المتوقع' : 'مستحق هذه الزيارة'}: ${((session.pricingPreview?.workerAmount ?? session.financial?.netAmount ?? session.workerAssignmentState?.workerAmount)!).toStringAsFixed(2)} ${session.pricingPreview?.currency ?? session.financial?.currency ?? session.workerAssignmentState?.currency ?? ''}',
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff047857),
                    ),
                    if (session.pricingPreview != null)
                      AppText.bodySmall(
                        'حصة الخدمة: ${session.pricingPreview!.serviceShareAmount?.toStringAsFixed(2) ?? '—'} • بدل النقل: ${session.pricingPreview!.travelFee?.toStringAsFixed(2) ?? '—'}',
                        color: _mutedTextColor,
                      ),
                  ],
                  if (session.id != null && !session.isTerminal) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _sessionAcceptanceLoading || !_canConfirmAcceptance
                            ? null
                            : () => _acceptSelectedSessions([session.id!]),
                        child: const Text('قبول هذه الزيارة'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffBFDBFE)),
          ),
          child: AppText.bodySmall(
            'اقبل كل زيارة تناسب جدولك من بطاقتها. تبقى بقية الزيارات متاحة لعمال آخرين.',
            fontWeight: FontWeight.w800,
            color: const Color(0xff1E3A8A),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptSingleSession() async {
    if (_order.id == null) return;
    if ((_schedule?.bookingDaysCount ?? 0) > 0 &&
        _schedule?.hasPersistedSessions != true) {
      AppToast.showErrorGlobal(
        'هذه الزيارة غير متاحة للقبول من حسابك حالياً. قد تتطلب مؤهلاً خاصاً أو عاملاً آخر. حدّث الطلب وتحقق من الزيارات المتاحة.',
      );
      return;
    }
    if (_schedule?.hasPersistedSessions == true) {
      final sessionId = _schedule!.sessions.first.id;
      if (sessionId != null) unawaited(_acceptSelectedSessions([sessionId]));
      return;
    }
    if (!OrderLifecyclePolicy.canAcceptReject(_order)) {
      AppToast.showErrorGlobal(
        OrderLifecyclePolicy.orderNoLongerAvailableMessage,
      );
      Navigator.of(context).pop(const _AcceptOrderSheetResult(accepted: false));
      return;
    }
    // A one-visit V2 booking is session-scoped. Legacy parent acceptance
    // skips visit acceptance proof and may recalculate the signed total.
    if (!await confirmWorkerActionTerms(context, cancelling: false)) return;
    if (!mounted) return;
    widget.bloc.add(
      AcceptOrderUsecaseEvent(
        params: AcceptOrderUsecaseParams(id: _order.id!),
        index: widget.index,
        context: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) =>
          previous.acceptOrderUsecaseStatus != BlocStatus.success &&
          current.acceptOrderUsecaseStatus == BlocStatus.success,
      buildWhen: (previous, current) =>
          previous.acceptOrderUsecaseStatus != current.acceptOrderUsecaseStatus,
      listener: (context, state) {
        Navigator.of(
          context,
        ).pop(const _AcceptOrderSheetResult(accepted: true));
      },
      builder: (context, state) {
        final accepting =
            state.acceptOrderUsecaseStatus == BlocStatus.loading ||
            _sessionAcceptanceLoading;

        return Container(
          height: context.height * .88,
          decoration: BoxDecoration(
            color: context.onPrimary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleMedium(
                            'مراجعة عرض العمل',
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.start,
                          ),
                          AppText.bodySmall(
                            _isMultiSession
                                ? 'راجع جميع الزيارات وحدد نطاق التزامك قبل القبول'
                                : 'الطلب #${_bookingCode()} • تحقق من المهام والمستحق قبل القبول',
                            color: _mutedTextColor,
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: accepting ? null : _dismissSheet,
                      child: Icon(
                        Icons.close,
                        color: accepting
                            ? const Color(0xff9CA3AF)
                            : _mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isMultiSession) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffECFDF5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: AppText.bodySmall(
                            'طلب متعدد الزيارات',
                            color: const Color(0xff047857),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_detailsLoading && !_detailsChecked) ...[
                        const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 12),
                        AppText.bodySmall(
                          'جاري تحميل جميع تفاصيل وإضافات الطلب...',
                          color: _mutedTextColor,
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_detailsError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffFECACA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppText.bodySmall(
                                _detailsError!,
                                color: context.error,
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _detailsLoading
                                    ? null
                                    : _loadOrderDetails,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة تحميل تفاصيل الطلب'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      WorkerOrderOverviewCard(order: _order),
                      const SizedBox(height: 12),
                      WorkerDetailSection(
                        title: 'المهام والخدمات المطلوبة',
                        icon: Icons.cleaning_services_outlined,
                        children: _serviceWidgets(),
                      ),
                      WorkerDetailSection(
                        title: _isMultiSession
                            ? 'جميع الزيارات'
                            : 'موعد ووقت الخدمة',
                        icon: Icons.schedule_outlined,
                        children: [_scheduleSection(context)],
                      ),
                      WorkerDetailSection(
                        title: _isEventAssistance
                            ? 'تفاصيل المناسبة'
                            : 'تفاصيل العقار',
                        icon: _isEventAssistance
                            ? Icons.event_available_outlined
                            : Icons.apartment_outlined,
                        children: _propertyDetailsRows(),
                      ),
                      WorkerDetailSection(
                        title: 'تفاصيل حصتي المالية',
                        icon: Icons.payments_outlined,
                        children: [
                          if (_order.workerPayableAmount == null)
                            const Text(
                              'ستظهر تفاصيل حصتك بعد تسعير الطلب من الخادم.',
                            )
                          else
                            WorkerPaymentSummary(
                              basePrice: null,
                              bookingBasePrice:
                                  _order.financialBookingBaseService,
                              travelFee:
                                  _order.financialTravelFee ??
                                  _order.myAssignment?.travelFee ??
                                  _order.travelFee,
                              addonsTotal: null,
                              totalPrice: _order.workerGrossTotal,
                              showAddonsTotal: false,
                              useWorkerShare: true,
                              serviceShareAmount:
                                  _order.financialServiceShare ??
                                  _order.myAssignment?.serviceShareAmount,
                              baseServiceShareAmount:
                                  _order.financialBaseServiceShare,
                              serviceAndOperationalShareAmount:
                                  _order.financialServiceAndOperationalShare,
                              specialServicesShareAmount:
                                  _order.financialSpecialServicesShare,
                              materialsShareAmount:
                                  _order.financialMaterialsShare,
                              adminMarginPercentage:
                                  _order.financialAdminMarginPercentage,
                              plannedWorkerCount:
                                  _order.financialPlannedWorkerCount ??
                                  _order.numberOfWorkers,
                              actualWorkerCount:
                                  _order.financialActualWorkerCount,
                              isFinal:
                                  (_order.numberOfWorkers ?? 1) <= 1 ||
                                  _order.isWorkerDistributionFinal,
                              hideGroupMaterialPrices:
                                  _order.hidesGroupMaterialPrices,
                              workerAmount: _order.workerPayableAmount,
                              adminMargin:
                                  _order.financialAdminMargin ??
                                  _order.myAssignment?.adminMarginAmount,
                            ),
                        ],
                      ),
                      WorkerDetailSection(
                        title: 'موقع المهمة',
                        icon: Icons.location_on_outlined,
                        children: [
                          AppText.bodyMedium(
                            _preAcceptanceAddressText(),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _borderColor)),
                ),
                child: _isMultiSession
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: accepting ? null : _dismissSheet,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.error,
                                    side: BorderSide(color: context.error),
                                  ),
                                  child: const Text('إغلاق'),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                          ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: accepting || !_canConfirmAcceptance
                                    ? null
                                    : _showSelectedSessionsPicker,
                                icon: const Icon(Icons.checklist_rtl),
                                label: const Text('اختيار عدة زيارات'),
                              ),
                            ),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: accepting ? null : _dismissSheet,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: context.error),
                                  color: context.error.withAlpha(20),
                                ),
                                child: Center(
                                  child: AppText.labelLarge(
                                    'إغلاق',
                                    color: context.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: accepting || !_canConfirmAcceptance
                                  ? null
                                  : _acceptSingleSession,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _canConfirmAcceptance
                                      ? context.primary
                                      : const Color(0xff9CA3AF),
                                ),
                                child: Center(
                                  child: accepting || _scheduleLoading
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: context.onPrimary,
                                          ),
                                        )
                                      : AppText.labelLarge(
                                          'تأكيد القبول',
                                          color: context.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
