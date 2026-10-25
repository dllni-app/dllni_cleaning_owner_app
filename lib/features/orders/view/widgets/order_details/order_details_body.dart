import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widgets/cancel_order_dialog.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/reject_order_usecase_use_case.dart';
import '../../../domain/usecases/start_travel_usecase_use_case.dart';
import '../../helpers/event_assistance_order_helper.dart';
import '../../helpers/order_address_visibility_helper.dart';
import '../../helpers/order_lifecycle_policy.dart';
import '../../helpers/order_mission_task_mapper.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../accept_order_bottom_sheet.dart';
import '../estate_info_card.dart';
import 'worker_order_overview_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final canAcceptReject = OrderLifecyclePolicy.canAcceptReject(widget.order);
    final canStartTravel = OrderLifecyclePolicy.canStartTravel(widget.order);
    final canCancel = OrderLifecyclePolicy.canCancel(widget.order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل المهمة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.order.bookingNumber?.isNotEmpty == true)
                    Text(
                      widget.order.bookingNumber!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            6.horizontalSpace,
            isSameDate(widget.order.createdAt, widget.order.scheduledDate)
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
                : const SizedBox(),
          ],
        ),
        const Divider(color: Colors.grey),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  WorkerOrderOverviewCard(order: widget.order),
                  const SizedBox(height: 14),
                  EstateInfoCard(order: widget.order),
                  const SizedBox(height: 14),
                  _buildServicesCard(context),
                  _buildOrderAddressCard(context),
                  if (_shouldShowCustomerContact) ...[
                    const SizedBox(height: 14),
                    _buildCustomerContactCard(context),
                  ],
                  const SizedBox(height: 14),
                  WorkerTeamStatusCard(order: widget.order),
                  if (OrderLifecyclePolicy.isAcceptedWaiting(widget.order))
                    const SizedBox(height: 14),
                  if (_shouldShowAssignedRooms)
                    WorkerRoomAssignmentsCard(order: widget.order),
                  const SizedBox(height: 14),
                  PaymentInfoCard(order: widget.order),
                  const SizedBox(height: 10),
                  if (canAcceptReject) _buildAcceptRejectActions(context),
                  if (canStartTravel)
                    _buildStartTravelActions(context, canCancel),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _shouldShowCustomerContact {
    final phone = widget.order.customer?.phone?.trim();
    return OrderLifecyclePolicy.hasCurrentWorkerAccepted(widget.order) &&
        phone != null &&
        phone.isNotEmpty;
  }

  Widget _buildCustomerContactCard(BuildContext context) {
    final phone = widget.order.customer!.phone!.trim();

    return Container(
      width: context.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium('التواصل مع العميل', fontWeight: FontWeight.w600),
          const SizedBox(height: 6),
          AppText.bodySmall(
            'تظهر وسائل التواصل بعد قبولك للمهمة.',
            color: const Color(0xff6B7280),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _launchContact('tel', phone),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('اتصال'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchContact('sms', phone),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('رسالة SMS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchContact(String scheme, String phone) async {
    final uri = Uri(scheme: scheme, path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    AppToast.showErrorGlobal(
      scheme == 'tel' ? 'تعذر فتح تطبيق الاتصال.' : 'تعذر فتح تطبيق الرسائل.',
    );
  }

  Widget _buildServicesCard(BuildContext context) {
    final tasks = OrderMissionTaskMapper.build(order: widget.order);
    final specialServices = widget.order.specialServices ?? const [];
    final specialPreview =
        widget.order.specialServicesPreview ?? const <Map<String, dynamic>>[];

    return Container(
      width: context.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium(
            'الغرف المطلوبة والخدمات الخاصة',
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withAlpha(42)),
          const SizedBox(height: 12),
          if (tasks.isEmpty &&
              specialServices.isEmpty &&
              specialPreview.isEmpty)
            AppText.bodySmall(
              'لم تُسجّل غرف أو خدمات خاصة في بيانات هذا الطلب',
              color: const Color(0xff6B7280),
              textAlign: TextAlign.start,
            )
          else ...[
            ...tasks.map(
              (task) => _buildServiceRow(
                task.detail == null || task.detail!.isEmpty
                    ? task.label
                    : '${task.label} • ${task.detail}',
                null,
              ),
            ),
            ...specialServices.map(
              (service) =>
                  _buildServiceRow(service.name, service.quantity?.round()),
            ),
            if (specialServices.isEmpty)
              ...specialPreview.map(
                (service) => _buildServiceRow(
                  service['name']?.toString(),
                  (service['quantity'] is num)
                      ? (service['quantity'] as num).round()
                      : null,
                ),
              ),
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
          const SizedBox(width: 6),
          Expanded(
            child: AppText.labelMedium(
              (name ?? '').trim().isEmpty ? 'خدمة' : name!,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.start,
            ),
          ),
          if (quantity != null) AppText.bodySmall('×$quantity'),
        ],
      ),
    );
  }

  Widget _buildOrderAddressCard(BuildContext context) {
    final neighborhood = widget.order.displayNeighborhoodName?.trim();
    final hideExactAddress = OrderLifecyclePolicy.isCustomerDataHidden(
      widget.order,
    );
    final useNeighborhoodOnly =
        hideExactAddress && neighborhood != null && neighborhood.isNotEmpty;
    final visibleAddress = useNeighborhoodOnly
        ? neighborhood
        : visibleOrderAddress(
            address:
                widget.order.propertyDetails?.address ??
                widget.order.locationName,
            status: hideExactAddress ? widget.order.status : null,
          );
    final address =
        visibleAddress.trim().isEmpty || visibleAddress.trim() == '-'
        ? 'الحي غير محدد'
        : visibleAddress;

    return Container(
      width: context.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium('عنوان العقار', fontWeight: FontWeight.w400),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withAlpha(42)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: context.secondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppText.labelMedium(
                  address,
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
                padding: const EdgeInsetsDirectional.symmetric(
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
        const SizedBox(height: 12),
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
                padding: const EdgeInsetsDirectional.symmetric(
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
                        'لا أرغب باستلام هذا الطلب',
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
                padding: const EdgeInsetsDirectional.symmetric(
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
        const SizedBox(height: 12),
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
            padding: const EdgeInsetsDirectional.symmetric(
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
  if (date1 == null || date2 == null) {
    return false;
  }

  final d1 = DateTime.parse(date1);
  final d2 = DateTime.parse(date2);

  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}
