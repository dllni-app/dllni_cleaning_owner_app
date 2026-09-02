import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/worker_session_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_enum_translations.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/event_assistance_order_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_address_visibility_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/property_attribute_labels_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/worker_payment_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _borderColor = Color(0xffE5E7EB);
const _mutedTextColor = Color(0xff6B7280);
const _titleTextColor = Color(0xff111827);

enum _AcceptOrderSheetCloseAction { accepted, dismissed }

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
  }) async {
    if (!OrderLifecyclePolicy.canAcceptReject(order)) {
      AppToast.showErrorGlobal(
        OrderLifecyclePolicy.orderNoLongerAvailableMessage,
      );
      return;
    }

    final closeAction =
        await showModalBottomSheet<_AcceptOrderSheetCloseAction>(
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

    if (!autoRejectOnClose) return;
    final orderId = order.id;
    if (orderId == null) return;
    if (closeAction == _AcceptOrderSheetCloseAction.accepted) return;

    bloc.add(
      RejectOrderUsecaseEvent(
        params: RejectOrderUsecaseParams(id: orderId),
        index: index,
      ),
    );
  }

  @override
  State<AcceptOrderBottomSheet> createState() => _AcceptOrderBottomSheetState();
}

class _AcceptOrderBottomSheetState extends State<AcceptOrderBottomSheet> {
  FetchOrdersUsecaseModelDataItem get _order => widget.order;

  WorkerBookingScheduleModel? _schedule;
  bool _scheduleChecked = false;
  bool _scheduleLoading = false;
  bool _sessionAcceptanceLoading = false;
  String? _scheduleError;

  bool get _isEventAssistance =>
      EventAssistanceOrderHelper.isEventAssistance(_order.propertyType);

  bool get _isMultiSession => _schedule?.isMultiDay == true;

  bool get _canConfirmAcceptance =>
      _scheduleChecked && !_scheduleLoading && _scheduleError == null;

  @override
  void initState() {
    super.initState();
    if (_order.id != null) {
      _loadSchedule();
    } else {
      _scheduleChecked = true;
    }
  }

  Future<void> _loadSchedule() async {
    final orderId = _order.id;
    if (orderId == null) return;
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
        _scheduleError = 'تعذر تحميل جدول الجلسات. أعد المحاولة قبل القبول.';
      });
    }
  }

  void _refreshAfterSessionAcceptance(int bookingId) {
    widget.bloc.add(
      FetchOrdersUsecaseEvent(
        params: widget.bloc.lastAppliedOrdersListFilter,
        isReload: true,
        silent: true,
      ),
    );
    widget.bloc.add(SyncOrderFromRealtimeEvent(bookingId: bookingId));
  }

  Future<void> _acceptAllSessions() async {
    final bookingId = _order.id;
    if (bookingId == null || _sessionAcceptanceLoading) return;

    setState(() => _sessionAcceptanceLoading = true);
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .acceptAllSessions(bookingId);
      if (!mounted) return;

      if (!result.allAccepted) {
        final message = result.rejected.isNotEmpty
            ? result.rejected.first.message
            : 'تعذر قبول جميع الجلسات. حدّث الطلب وحاول مجدداً.';
        AppToast.showErrorGlobal(message);
        setState(() => _sessionAcceptanceLoading = false);
        await _loadSchedule();
        return;
      }

      _refreshAfterSessionAcceptance(bookingId);
      AppToast.showSuccessGlobal('تم قبول جميع الجلسات المتاحة');
      Navigator.of(context).pop(_AcceptOrderSheetCloseAction.accepted);
    } catch (_) {
      if (!mounted) return;
      AppToast.showErrorGlobal(
        'تعذر قبول جميع الجلسات. حدّث الطلب وحاول مجدداً.',
      );
      setState(() => _sessionAcceptanceLoading = false);
      await _loadSchedule();
    }
  }

  Future<void> _showSelectedSessionsPicker() async {
    final schedule = _schedule;
    if (schedule == null || _sessionAcceptanceLoading) return;

    final sessions = schedule.sessions
        .where((session) => session.id != null && !session.isTerminal)
        .toList(growable: false);
    if (sessions.isEmpty) {
      AppToast.showErrorGlobal('لا توجد جلسات متاحة للاختيار حالياً.');
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
                                  'حدد الجلسات التي يمكنك قبولها',
                                  fontWeight: FontWeight.w800,
                                ),
                                const SizedBox(height: 4),
                                AppText.bodySmall(
                                  'سيتم حجز الجلسات التي تختارها لك، وتبقى باقي الجلسات متاحة لعمال آخرين.',
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
                              : () => Navigator.of(sheetContext).pop(
                                    selectedIds.toList(growable: false),
                                  ),
                          child: Text(
                            selectedIds.isEmpty
                                ? 'اختر جلسة واحدة على الأقل'
                                : 'قبول ${selectedIds.length} جلسة',
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
    if (bookingId == null || _sessionAcceptanceLoading) return;

    setState(() => _sessionAcceptanceLoading = true);
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .acceptSelectedSessions(
            bookingId: bookingId,
            sessionIds: sessionIds,
          );
      if (!mounted) return;

      if (result.acceptedSessionIds.isEmpty) {
        final message = result.rejected.isNotEmpty
            ? result.rejected.first.message
            : 'تعذر قبول الجلسات المحددة.';
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
            ? 'تم قبول $acceptedCount جلسة'
            : 'تم قبول $acceptedCount جلسة، وتعذر قبول $rejectedCount جلسة',
      );
      Navigator.of(context).pop(_AcceptOrderSheetCloseAction.accepted);
    } catch (_) {
      if (!mounted) return;
      AppToast.showErrorGlobal('تعذر قبول الجلسات المحددة. حاول مجدداً.');
      setState(() => _sessionAcceptanceLoading = false);
      await _loadSchedule();
    }
  }

  String _serviceName() {
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
    return 'الجلسة ${session.sequence} من ${_schedule?.daysCount ?? 1}';
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

  num _grossWorkerTotal() {
    return _order.workerGrossTotal;
  }

  void _dismissSheet() {
    Navigator.of(context).pop(_AcceptOrderSheetCloseAction.dismissed);
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.primaryContainer),
        const SizedBox(width: 8),
        AppText.bodyLarge(title, fontWeight: FontWeight.bold),
      ],
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

    if (_isEventAssistance) {
      return [
        AppText.bodyMedium(
          _serviceName(),
          fontWeight: FontWeight.w700,
          color: _titleTextColor,
        ),
      ];
    }

    if (services.isEmpty && addons.isEmpty) {
      return [
        AppText.bodySmall(
          'لا توجد خدمات إضافية',
          color: _mutedTextColor,
          textAlign: TextAlign.start,
        ),
      ];
    }

    return [
      ...services.map((s) => _serviceLine(s.name, s.quantity)),
      ...addons.map((a) => _serviceLine(a.name, a.quantity)),
    ];
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
    if (_isEventAssistance) {
      return [
        _orderInfoRow(
          label: 'نوع المناسبة',
          value: CleaningEnumTranslations.eventType(
            _order.propertyDetails?.eventType,
          ),
        ),
        _orderInfoRow(
          label: 'الخدمة المطلوبة',
          value: _serviceName(),
          withDivider: false,
        ),
      ];
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

    final cleaningModeLabel = CleaningEnumTranslations.preferArabicLabel(
      _order.propertyDetails?.cleaningModeLabel,
      _order.propertyDetails?.cleaningMode,
      CleaningEnumTranslations.cleaningMode,
    );
    final showCleaningMode =
        cleaningModeLabel.trim().isNotEmpty && cleaningModeLabel != 'غير محدد';

    final rows = <Widget>[
      if (showPropertyType)
        _orderInfoRow(
          label: 'نوع المكان',
          value: propertyTypeLabel,
          withDivider: showCleaningMode || visibleItems.isNotEmpty,
        ),
      if (showCleaningMode)
        _orderInfoRow(
          label: 'نوع التنظيف',
          value: cleaningModeLabel,
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
    if (_scheduleLoading && !_scheduleChecked) {
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
          label: const Text('إعادة تحميل الجلسات'),
        ),
      ]);
    }
    final schedule = _schedule;
    if (schedule == null || !schedule.isMultiDay) {
      return _detailCard(context, [
        _orderInfoRow(label: 'يوم الخدمة', value: _formatWeekday()),
        _orderInfoRow(label: 'التاريخ', value: _formatDate()),
        _orderInfoRow(
          label: 'الوقت',
          value: _formatTime(),
          withDivider: false,
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailCard(context, [
          _orderInfoRow(
            label: _isEventAssistance ? 'عدد الأيام' : 'عدد الجلسات',
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
            'يمكنك قبول جميع الجلسات، أو تحديد الجلسات التي تستطيع تنفيذها فقط. الجلسات التي لا تقبلها تبقى متاحة لعمال مؤهلين آخرين.',
            fontWeight: FontWeight.w800,
            color: const Color(0xff1E3A8A),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  void _acceptSingleSession() {
    if (_order.id == null) return;
    if (!OrderLifecyclePolicy.canAcceptReject(_order)) {
      AppToast.showErrorGlobal(
        OrderLifecyclePolicy.orderNoLongerAvailableMessage,
      );
      Navigator.of(context).pop(_AcceptOrderSheetCloseAction.dismissed);
      return;
    }
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
        Navigator.of(context).pop(_AcceptOrderSheetCloseAction.accepted);
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
                            'قبول الطلب #${_bookingCode()}',
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.start,
                          ),
                          AppText.bodySmall(
                            _isMultiSession
                                ? 'راجع جميع الجلسات وحدد نطاق التزامك قبل القبول'
                                : 'يرجى تأكيد تفاصيل الطلب قبل القبول',
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
                            'طلب متعدد الجلسات',
                            color: const Color(0xff047857),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _sectionTitle(
                        context,
                        Icons.receipt_long_outlined,
                        'بيانات الطلب',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        _orderInfoRow(
                          label: 'السعر الإجمالي',
                          value: _grossWorkerTotal().formatMoney(),
                          withDivider: false,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.cleaning_services_outlined,
                        'الخدمات المطلوبة',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, _serviceWidgets()),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.schedule,
                        _isMultiSession ? 'جميع الجلسات' : 'موعد ووقت الخدمة',
                      ),
                      const SizedBox(height: 10),
                      _scheduleSection(context),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        _isEventAssistance
                            ? Icons.event_available_outlined
                            : Icons.apartment_outlined,
                        _isEventAssistance
                            ? 'تفاصيل المناسبة'
                            : 'تفاصيل العقار',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, _propertyDetailsRows()),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.payments_outlined,
                        'تفاصيل الدفع',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        WorkerPaymentSummary(
                          basePrice: _order.basePrice,
                          travelFee: _order.travelFee,
                          addonsTotal: _order.addonsTotal,
                          totalPrice: _order.workerGrossTotal,
                          showAddonsTotal: true,
                          adminMargin: _order.adminMargin,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.location_on_outlined,
                        'عنوان العقار',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        AppText.bodyMedium(
                          _preAcceptanceAddressText(),
                          textAlign: TextAlign.start,
                        ),
                      ]),
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
                                  child: Text(
                                    widget.autoRejectOnClose
                                        ? 'رفض الطلب'
                                        : 'إلغاء',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed:
                                      accepting || !_canConfirmAcceptance
                                          ? null
                                          : _acceptAllSessions,
                                  child: accepting
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: context.onPrimary,
                                          ),
                                        )
                                      : const Text('قبول جميع الجلسات'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: accepting || !_canConfirmAcceptance
                                  ? null
                                  : _showSelectedSessionsPicker,
                              icon: const Icon(Icons.checklist_rtl),
                              label: const Text(
                                'تحديد الجلسات التي يمكنني قبولها',
                              ),
                            ),
                          ),
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
                                    widget.autoRejectOnClose
                                        ? 'رفض الطلب'
                                        : 'إلغاء',
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
