import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../../core/widgets/cancel_order_dialog.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/reject_order_usecase_use_case.dart';
import '../../../domain/usecases/start_travel_usecase_use_case.dart';
import '../../helpers/cleaning_enum_translations.dart';
import '../../helpers/event_assistance_order_helper.dart';
import '../../helpers/order_address_visibility_helper.dart';
import '../../helpers/order_lifecycle_policy.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../accept_order_bottom_sheet.dart';
import '../estate_info_card.dart';
import '../order_info_card.dart';
import '../payment_info_card.dart';
import '../worker_room_assignments_card.dart';

class OrderDetailsBody extends StatefulWidget {
  const OrderDetailsBody({
    super.key,
    required this.bloc,
    required this.index,
    required this.order,
  });

  final OrdersBloc bloc;
  final int index;
  final FetchOrdersUsecaseModelDataItem order;

  @override
  State<OrderDetailsBody> createState() => _OrderDetailsBodyState();
}

class _OrderDetailsBodyState extends State<OrderDetailsBody> {
  bool get _isEventAssistance =>
      EventAssistanceOrderHelper.isEventAssistance(widget.order.propertyType);

  bool get _shouldShowAssignedRooms =>
      !_isEventAssistance &&
      widget.order.numberOfWorkers != null &&
      widget.order.numberOfWorkers! > 1;

  String _formatHours(double? hours) {
    if (hours == null) return '-';
    return hours % 1 == 0 ? hours.toInt().toString() : hours.toString();
  }


  List<MapEntry<String, String>> get _summaryRows {
    final bookedHours = EventAssistanceOrderHelper.resolveBookedHours(
      propertyHours: widget.order.propertyDetails?.hours,
      totalHours: widget.order.totalHours,
      estimatedHours: widget.order.estimatedHours,
    );

    return [
      MapEntry('إجمالي ساعات العمل', _formatHours(bookedHours)),
      MapEntry(
        _isEventAssistance ? 'عدد الضيوف : ' : 'المساحة التقديرية',
        _isEventAssistance
            ? '${widget.order.propertyDetails?.guestCount ?? '-'}'
            : widget.order.estimatedSqm ?? '-',
      ),
      // MapEntry('سعر الخدمة : ', _formatPrice(widget.order.basePrice)),
      // MapEntry('سعر التوصيل : ', _formatPrice(widget.order.travelFee)),
      MapEntry('السعر الإجمالي', widget.order.totalPrice.formatMoney()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canAcceptReject = OrderLifecyclePolicy.canAcceptReject(widget.order);
    final canStartTravel = OrderLifecyclePolicy.canStartTravel(widget.order);
    final canCancel = OrderLifecyclePolicy.canCancel(widget.order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back, color: Colors.black),
            ),
            Expanded(
              child: AppText.headlineMedium(
                'تفاصيل الطلب ${widget.order.bookingNumber}',
                textAlign: TextAlign.start,
              ),
            ),
            6.horizontalSpace,

            isSameDate(widget.order.createdAt,widget.order.scheduledDate)
                ? Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: context.error.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 3.5,
                    backgroundColor: context.error,
                  ),
                  const SizedBox(width: 6),
                  AppText.labelSmall(
                    'طلب ساخن',
                    color: context.error,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            )
                : SizedBox(),
          ],
        ),
        Divider(color: Colors.grey,),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 28),
                  DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      radius: Radius.circular(10),
                      color: context.primaryContainer,
                      strokeWidth: 2,
                      dashPattern: [8, 4],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: context.primaryContainer.withAlpha(31),
                      ),
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _summaryRows
                            .map(
                              (row) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(

                                    children: [
                                      AppText.labelSmall(
                                        row.key,
                                        color: context.primary,
                                        fontWeight: FontWeight.w700,
                                        textAlign: TextAlign.center,

                                      ),
                                      SizedBox(height: 8),
                                      AppText.labelSmall(
                                        row.value,
                                        color: context.primary,
                                        fontWeight: FontWeight.w500,
                                        textAlign: TextAlign.start,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  OrderInfoCard(order: widget.order),
                  SizedBox(height: 14),
                  EstateInfoCard(order: widget.order),
                  SizedBox(height: 14),
                  _buildServicesCard(context),
                  // SizedBox(height: 14),
                  // _buildOrderAddressCard(context),
                  SizedBox(height: 14),
                  WorkerTeamStatusCard(order: widget.order),
                  if (OrderLifecyclePolicy.isAcceptedWaiting(widget.order))
                    SizedBox(height: 14),
                  if (_shouldShowAssignedRooms)
                    WorkerRoomAssignmentsCard(order: widget.order),
                  SizedBox(height: 14),
                  PaymentInfoCard(order: widget.order),
                  SizedBox(height: 10),
                  if (canAcceptReject) _buildAcceptRejectActions(context),
                  if (canStartTravel)
                    _buildStartTravelActions(context, canCancel),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCard(BuildContext context) {
    final services = widget.order.services ?? const [];
    final addons = widget.order.addons ?? const [];
    final hasItems = services.isNotEmpty || addons.isNotEmpty;

    return Container(
      width: context.width,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium('الخدمات المطلوبة', fontWeight: FontWeight.w400),
          SizedBox(height: 12),
          Divider(color: Colors.black.withAlpha(42)),
          SizedBox(height: 12),
          if (!hasItems)
            AppText.bodySmall(
              'لا توجد خدمات إضافية',
              color: const Color(0xff6B7280),
              textAlign: TextAlign.start,
            )
          else ...[
            ...services.map((service) => _buildServiceRow(service.name, service.quantity)),
            ...addons.map((addon) => _buildServiceRow(addon.name, addon.quantity)),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceRow(String? name, int? quantity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: context.primary),
          SizedBox(width: 6),
          Expanded(
            child: AppText.labelMedium(
              (name ?? '').trim().isEmpty ? 'خدمة' : name!,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.start,
            ),
          ),
          AppText.bodySmall('x${quantity ?? 1}'),
        ],
      ),
    );
  }

  Widget _buildOrderAddressCard(BuildContext context) {
    final address = visibleOrderAddress(
      address:
          widget.order.propertyDetails?.address ?? widget.order.locationName,
      status: widget.order.status,
    );

    return Container(
      width: context.width,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium('عنوان العقار', fontWeight: FontWeight.w400),
          SizedBox(height: 12),
          Divider(color: Colors.black.withAlpha(42)),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: context.secondary,
                size: 18,
              ),
              SizedBox(width: 6),
              Expanded(
                child: AppText.labelMedium(
                  address.trim().isEmpty ? 'العنوان غير متوفر' : address,
                  fontWeight: FontWeight.w300,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptRejectActions(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<OrdersBloc, OrdersState>(
          bloc: widget.bloc,
          builder: (context, state) {
            final loading = OrderLifecyclePolicy.isLoadingForOrderIndex(
              state: state,
              orderIndex: widget.index,
              actionStatus: state.acceptOrderUsecaseStatus,
            );
            return InkWell(
              onTap: loading
                  ? null
                  : () {
                      AcceptOrderBottomSheet.show(
                        context,
                        order: widget.order,
                        bloc: widget.bloc,
                        index: widget.index,
                      );
                    },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.primary,
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                width: context.width,
                child: loading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: context.onPrimary,
                          ),
                        ),
                      )
                    : AppText.labelLarge(
                        'قبول الطلب',
                        color: context.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            );
          },
        ),
        SizedBox(height: 12),
        BlocBuilder<OrdersBloc, OrdersState>(
          bloc: widget.bloc,
          builder: (context, state) {
            final loading = OrderLifecyclePolicy.isLoadingForOrderIndex(
              state: state,
              orderIndex: widget.index,
              actionStatus: state.rejectOrderUsecaseStatus,
            );
            return InkWell(
              onTap: loading || widget.order.id == null
                  ? null
                  : () {
                      widget.bloc.add(
                        RejectOrderUsecaseEvent(
                          params: RejectOrderUsecaseParams(
                            id: widget.order.id!,
                          ),
                          index: widget.index,
                        ),
                      );
                    },
              child: Container(
                width: context.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.error.withAlpha(20),
                  border: Border.all(color: context.error),
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                  vertical: 14,
                ),
                child: loading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: context.error,
                          ),
                        ),
                      )
                    : AppText.labelLarge(
                        'رفض',
                        color: context.error,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStartTravelActions(BuildContext context, bool canCancel) {
    return Column(
      children: [
        BlocBuilder<OrdersBloc, OrdersState>(
          bloc: widget.bloc,
          builder: (context, state) {
            final loading = OrderLifecyclePolicy.isLoadingForOrderIndex(
              state: state,
              orderIndex: widget.index,
              actionStatus: state.startTravelUsecaseStatus,
            );
            return InkWell(
              onTap: loading || widget.order.id == null
                  ? null
                  : () {
                      if (!OrderLifecyclePolicy.isStartTravelWithinAllowedWindow(
                        widget.order,
                      )) {
                        AppToast.showErrorGlobal(
                          OrderLifecyclePolicy.startTravelUnavailableMessage,
                        );
                        return;
                      }
                      widget.bloc.add(
                        StartTravelUsecaseEvent(
                          params: StartTravelUsecaseParams(
                            id: widget.order.id!,
                          ),
                          index: widget.index,
                        ),
                      );
                    },
              child: Container(
                width: context.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.primary,
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: loading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: context.onPrimary,
                          ),
                        ),
                      )
                    : AppText.labelLarge(
                        'أنا في الطريق',
                        color: context.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            );
          },
        ),
        SizedBox(height: 12),
        InkWell(
          onTap: canCancel
              ? () {
                  CancelOrderDialog.show(
                    context,
                    bloc: widget.bloc,
                    orderId: widget.order.id!,
                    orderNum: widget.order.bookingNumber!,
                    index: widget.index,
                  );
                }
              : null,
          child: Container(
            width: context.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.error.withAlpha(20),
              border: Border.all(color: context.error),
            ),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 6,
              vertical: 14,
            ),
            child: AppText.labelLarge(
              'إلغاء',
              color: context.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

bool isSameDate(String? date1, String? date2) {
  // إذا كانت إحدى القيمتين (أو كلتاهما) null، نعتبرهما غير متساويتين
  if (date1 == null || date2 == null) {
    return false;
  }

  // تحويل النصوص إلى كائنات DateTime
  DateTime d1 = DateTime.parse(date1);
  DateTime d2 = DateTime.parse(date2);

  // مقارنة الأجزاء الأساسية وإرجاع النتيجة كـ bool
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}
