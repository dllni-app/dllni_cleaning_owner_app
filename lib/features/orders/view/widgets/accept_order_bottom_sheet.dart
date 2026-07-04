import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_enum_translations.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/event_assistance_order_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_address_visibility_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/property_attribute_labels_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
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

  bool get _isEventAssistance =>
      EventAssistanceOrderHelper.isEventAssistance(_order.propertyType);

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
    return CleaningArabicTimeFormatter.formatFromScheduledTimeField(
      _order.scheduledTime,
    );
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
          label: 'نوع المكان',
          value: CleaningEnumTranslations.venueType(
            _order.propertyDetails?.venueType,
          ),
        ),
        _orderInfoRow(
          label: 'عدد الخدمة المطلوبة',
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

    return List.generate(visibleItems.length, (index) {
      final item = visibleItems[index];
      final isLast = index == visibleItems.length - 1;

      return _orderInfoRow(
        label: item['label'],
        value: PropertyAttributeLabelsHelper.formatCount(item['value']),
        withDivider: !isLast,
      );
    });
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
        final accepting = state.acceptOrderUsecaseStatus == BlocStatus.loading;

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
                            'يرجى تأكيد تفاصيل الطلب قبل القبول',
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
                      _sectionTitle(
                        context,
                        Icons.person_outline_rounded,
                        'بيانات الطلب',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        _orderInfoRow(
                          label: 'اسم العميل',
                          value: _valueOrDash(_order.customer?.name),
                        ),
                        _orderInfoRow(
                          label: 'رقم الهاتف',
                          value: _valueOrDash(
                            _order.customer?.phone.formatAsPhoneNumber,
                          ),
                        ),
                        _orderInfoRow(
                          label: 'السعر الإجمالي',
                          value: _order.totalPrice.formatMoney(),
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
                        'موعد ووقت الخدمة',
                      ),
                      const SizedBox(height: 10),
                      _detailCard(context, [
                        _orderInfoRow(label: 'التاريخ', value: _formatDate()),
                        _orderInfoRow(
                          label: 'الوقت',
                          value: _formatTime(),
                          withDivider: false,
                        ),
                      ]),
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
                          totalPrice: _order.totalPrice,
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
                        if (_order.displayNeighborhoodName != null)
                          _orderInfoRow(
                            label: 'الحي',
                            value: _order.displayNeighborhoodName!,
                          ),
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
                                if (!OrderLifecyclePolicy.canAcceptReject(
                                  _order,
                                )) {
                                  AppToast.showErrorGlobal(
                                    OrderLifecyclePolicy
                                        .orderNoLongerAvailableMessage,
                                  );
                                  Navigator.of(
                                    context,
                                  ).pop(_AcceptOrderSheetCloseAction.dismissed);
                                  return;
                                }
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
