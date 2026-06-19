import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/event_assistance_order_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_address_visibility_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_details_to_list_item_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
  late FetchOrdersUsecaseModelDataItem _order;
  bool _detailsRequested = false;
  bool _detailsLoaded = false;

  bool get _isEventAssistance =>
      EventAssistanceOrderHelper.isEventAssistance(_order.propertyType);

  bool get _isLoadingDetails => _detailsRequested && !_detailsLoaded;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _requestFullOrderDetails();
  }

  void _requestFullOrderDetails() {
    if (_detailsRequested) return;
    final id = _order.id;
    if (id == null) {
      _detailsLoaded = true;
      return;
    }
    _detailsRequested = true;
    widget.bloc.add(
      FetchOrderDetailsUsecaseEvent(
        params: FetchOrderDetailsUsecaseParams(id: id),
      ),
    );
  }

  FetchOrdersUsecaseModelDataItem _mapDetails(
    FetchOrderDetailsUsecaseModelData details,
  ) {
    return OrderDetailsToListItemMapper.fromDetails(details).withTeamData(
      assignmentMode: details.assignmentMode,
      numberOfWorkers: details.numberOfWorkers,
      workerAcceptance: details.workerAcceptance,
      workerAssignments: details.workerAssignments,
      roomAssignments: details.roomAssignments,
      myAssignment: details.myAssignment,
    );
  }

  void _applyDetailsIfCurrentOrder(OrdersState state) {
    final details = state.orderDetailsUsecase?.data;
    if (details == null || details.id != _order.id || !mounted) return;
    setState(() {
      _order = _mapDetails(details);
      _detailsLoaded = true;
    });
  }

  void _markDetailsLoadFinishedIfNeeded(OrdersState state) {
    if (!_detailsRequested || _detailsLoaded || !mounted) return;
    if (state.orderDetailsUsecaseStatus == BlocStatus.failed) {
      setState(() => _detailsLoaded = true);
    }
  }

  String _serviceName() {
    return EventAssistanceOrderHelper.serviceTitle(
      propertyType: _order.propertyType,
      customService: _order.propertyDetails?.customService,
    );
  }

  String _formatDate() {
    final raw = _order.scheduledDate;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _formatTime() {
    final raw = _order.scheduledTime;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse('2000-01-01T$raw');
    if (parsed == null) return raw;
    return DateFormat('hh:mm a', 'en').format(parsed);
  }

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

  String _moneyLabel(num? amount) {
    if (amount == null) return '-';
    return '${amount.toStringAsFixed(2)} ل.س';
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

  Widget _loadingDetailsNotice() {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppText.bodySmall(
            'جاري تحميل تفاصيل الخدمات...',
            color: _mutedTextColor,
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Widget _serviceLine({
    required String name,
    int? quantity,
    FontWeight fontWeight = FontWeight.w700,
    Color color = _titleTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: AppText.bodyMedium(
              name,
              fontWeight: fontWeight,
              textAlign: TextAlign.start,
              color: color,
            ),
          ),
          AppText.bodySmall(
            'x${quantity ?? 1}',
            color: _mutedTextColor,
          ),
        ],
      ),
    );
  }

  List<Widget> _regularServiceWidgets() {
    final services = _order.services ?? const [];
    final addons = _order.addons ?? const [];
    if (_isLoadingDetails && services.isEmpty && addons.isEmpty) {
      return [_loadingDetailsNotice()];
    }
    if (services.isEmpty && addons.isEmpty) {
      return [
        AppText.bodySmall(
          'لا توجد بنود خدمة مفصلة',
          color: _mutedTextColor,
        ),
      ];
    }

    return [
      ...services.map(
        (s) => _serviceLine(
          name: s.name ?? 'خدمة',
          quantity: s.quantity,
        ),
      ),
      ...addons.map(
        (a) => _serviceLine(
          name: a.name ?? 'إضافة',
          quantity: a.quantity,
          fontWeight: FontWeight.w500,
          color: const Color(0xff374151),
        ),
      ),
    ];
  }

  List<Widget> _eventAssistanceWidgets() {
    final bookedHours = EventAssistanceOrderHelper.resolveBookedHours(
      propertyHours: _order.propertyDetails?.hours,
      totalHours: _order.totalHours,
      estimatedHours: _order.estimatedHours,
    );

    return [
      AppText.bodyMedium(
        _serviceName(),
        fontWeight: FontWeight.w700,
        color: _titleTextColor,
      ),
      if (_order.propertyDetails?.guestCount != null) ...[
        const SizedBox(height: 8),
        AppText.bodySmall(
          'عدد الضيوف: ${_order.propertyDetails!.guestCount}',
          color: _mutedTextColor,
        ),
      ],
      if ((_order.propertyDetails?.venueType ?? '').isNotEmpty) ...[
        const SizedBox(height: 4),
        AppText.bodySmall(
          'نوع المكان: ${EventAssistanceOrderHelper.venueTypeLabelAr(_order.propertyDetails?.venueType)}',
          color: _mutedTextColor,
        ),
      ],
      const SizedBox(height: 8),
      AppText.bodySmall(
        'مدة الحجز: ${EventAssistanceOrderHelper.formatHoursDetail(bookedHours)}',
        color: _mutedTextColor,
      ),
      if ((_order.propertyDetails?.specialRequirement ?? '').isNotEmpty) ...[
        const SizedBox(height: 4),
        AppText.bodySmall(
          'متطلبات خاصة: ${_order.propertyDetails!.specialRequirement}',
          color: _mutedTextColor,
        ),
      ],
    ];
  }

  List<Widget> _propertyDetailsRows() {
    if (_isEventAssistance) {
      return [
        _orderInfoRow(
          label: 'نوع المناسبة',
          value: EventAssistanceOrderHelper.eventTypeLabelAr(
            _order.propertyDetails?.eventType,
          ),
        ),
        _orderInfoRow(
          label: 'نوع المكان',
          value: _valueOrDash(
            EventAssistanceOrderHelper.venueTypeLabelAr(
              _order.propertyDetails?.venueType,
            ),
          ),
        ),
        _orderInfoRow(
          label: 'الخدمة المطلوبة',
          value: _serviceName(),
          withDivider: false,
        ),
      ];
    }

    final property = _order.propertyDetails;
    return [
      _orderInfoRow(
        label: 'عدد الغرف',
        value: '${property?.rooms ?? _order.numberOfRooms ?? '-'}',
      ),
      _orderInfoRow(
        label: 'غرف النوم',
        value: '${property?.bedRooms ?? '-'}',
      ),
      _orderInfoRow(
        label: 'الحمامات',
        value: '${property?.bathrooms ?? '-'}',
      ),
      _orderInfoRow(
        label: 'المطبخ',
        value: (property?.kitchenIncluded == true || property?.kitchen != null)
            ? 'موجود'
            : '-',
      ),
      _orderInfoRow(
        label: 'حجم غرفة المعيشة',
        value: _valueOrDash(property?.livingRoomSize),
        withDivider: false,
      ),
    ];
  }

  void _dismissSheet() {
    Navigator.of(context).pop(_AcceptOrderSheetCloseAction.dismissed);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) =>
          previous.acceptOrderUsecaseStatus != current.acceptOrderUsecaseStatus ||
          previous.orderDetailsUsecaseStatus != current.orderDetailsUsecaseStatus ||
          previous.orderDetailsUsecase != current.orderDetailsUsecase,
      listener: (context, state) {
        if (state.acceptOrderUsecaseStatus == BlocStatus.success) {
          Navigator.of(context).pop(_AcceptOrderSheetCloseAction.accepted);
          return;
        }
        _applyDetailsIfCurrentOrder(state);
        _markDetailsLoadFinishedIfNeeded(state);
      },
      builder: (context, state) {
        final accepting = state.acceptOrderUsecaseStatus == BlocStatus.loading;
        final hideCustomerData = OrderLifecyclePolicy.isCustomerDataHidden(
          _order,
        );

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
                            _isLoadingDetails
                                ? 'يتم تحميل تفاصيل الطلب الكاملة من الخادم'
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
                      if (_isLoadingDetails) ...[
                        _detailCard(context, [_loadingDetailsNotice()]),
                        const SizedBox(height: 16),
                      ],
                      _sectionTitle(
                        context,
                        Icons.person_outline_rounded,
                        'بيانات الطلب',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        if (!hideCustomerData)
                          _orderInfoRow(
                            label: 'اسم العميل',
                            value: _valueOrDash(_order.customer?.name),
                          ),
                        if (!hideCustomerData)
                          _orderInfoRow(
                            label: 'رقم الهاتف',
                            value: _valueOrDash(_order.customer?.phone),
                          ),
                        _orderInfoRow(
                          label: 'السعر الإجمالي',
                          value: _moneyLabel(_order.totalPrice),
                          withDivider: false,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.cleaning_services_outlined,
                        'نوع الخدمة',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        AppText.bodyMedium(
                          _serviceName(),
                          fontWeight: FontWeight.w700,
                          color: _titleTextColor,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.schedule,
                        'موعد ووقت الخدمة',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.bodySmall(
                                    'التاريخ',
                                    color: _mutedTextColor,
                                  ),
                                  const SizedBox(height: 4),
                                  AppText.bodyMedium(
                                    _formatDate(),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.bodySmall(
                                    'الوقت',
                                    color: _mutedTextColor,
                                  ),
                                  const SizedBox(height: 4),
                                  AppText.bodyMedium(
                                    _formatTime(),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        _isEventAssistance
                            ? Icons.event_available_outlined
                            : Icons.apartment_outlined,
                        _isEventAssistance ? 'تفاصيل المناسبة' : 'تفاصيل العقار',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, _propertyDetailsRows()),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.checklist_rounded,
                        'الخدمات المطلوبة',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(
                        context,
                        _isEventAssistance
                            ? _eventAssistanceWidgets()
                            : _regularServiceWidgets(),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle(
                        context,
                        Icons.payments_outlined,
                        'تفاصيل الدفع',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        _orderInfoRow(
                          label: 'سعر الخدمة الأساس',
                          value: _moneyLabel(_order.basePrice),
                        ),
                        _orderInfoRow(
                          label: 'إجمالي الإضافات',
                          value: _moneyLabel(_order.addonsTotal),
                        ),
                        _orderInfoRow(
                          label: 'رسوم التوصيل',
                          value: _moneyLabel(_order.travelFee),
                        ),
                        _orderInfoRow(
                          label: 'المبلغ الكلي',
                          value: _moneyLabel(_order.totalPrice),
                          withDivider: false,
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
                          visibleOrderAddress(
                            address:
                                _order.propertyDetails?.address ??
                                _order.locationName,
                            status: _order.status,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _detailCard(context, [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              color: context.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppText.bodySmall(
                                'سيتم إشعار العميل مباشرة بعد قبول الطلب',
                                color: context.primaryContainer,
                                fontWeight: FontWeight.w700,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ],
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
                child: Row(
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
                              widget.autoRejectOnClose ? 'رفض الطلب' : 'إلغاء',
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
                        onTap: accepting
                            ? null
                            : () {
                                if (_order.id == null) return;
                                widget.bloc.add(
                                  AcceptOrderUsecaseEvent(
                                    params: AcceptOrderUsecaseParams(
                                      id: _order.id!,
                                    ),
                                    index: widget.index,
                                    context: context,
                                  ),
                                );
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: context.primary,
                          ),
                          child: Center(
                            child: accepting
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
