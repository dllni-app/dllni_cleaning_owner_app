import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../../core/widgets/cancel_order_dialog.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/reject_order_usecase_use_case.dart';
import '../../../domain/usecases/start_travel_usecase_use_case.dart';
import '../../helpers/order_lifecycle_policy.dart';
import 'worker_order_requirements_card.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../accept_order_bottom_sheet.dart';
import '../estate_info_card.dart';
import 'worker_order_overview_card.dart';
import '../payment_info_card.dart';

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
                  // The overview already states the current accepted/team
                  // status. Avoid a second large banner repeating it.
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

  Widget _buildServicesCard(BuildContext context) =>
      WorkerOrderRequirementsCard(order: widget.order);

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
    final tooEarly = !OrderLifecyclePolicy.isStartTravelWithinAllowedWindow(
      widget.order,
    );
    return Column(
      children: [
        if (tooEarly) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xff64748B), size: 19),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    OrderLifecyclePolicy.startTravelUnavailableMessage,
                    style: TextStyle(color: Color(0xff64748B), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        BlocBuilder<OrdersBloc, OrdersState>(
          bloc: widget.bloc,
          builder: (context, state) {
            final loading = OrderLifecyclePolicy.isLoadingForOrderIndex(
              state: state,
              orderIndex: widget.index,
              actionStatus: state.startTravelUsecaseStatus,
            );
            return InkWell(
              onTap: loading || tooEarly || widget.order.id == null
                  ? null
                  : () {
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
                  color: tooEarly ? const Color(0xffCBD5E1) : context.primary,
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
                        color: tooEarly
                            ? const Color(0xff475569)
                            : context.onPrimary,
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
                    cancellationPenaltyAmount:
                        widget.order.workerCancellationPenaltyAmount,
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
