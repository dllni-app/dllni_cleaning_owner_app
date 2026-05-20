import 'package:common_package/common_package.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../../core/widgets/cancel_order_dialog.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/reject_order_usecase_use_case.dart';
import '../../../domain/usecases/start_travel_usecase_use_case.dart';
import '../../helpers/order_lifecycle_policy.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../accept_order_bottom_sheet.dart';
import '../estate_info_card.dart';
import '../order_info_card.dart';
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
  final List<String> titles = [
    'إجمالي عدد\nساعات العمل',
    'المساحة\nالتقديرية',
    'السعر\nالإجمالي',
  ];
  late List<String> val;

  @override
  void initState() {
    super.initState();
    val = [
      widget.order.totalHours.toString(),
      widget.order.estimatedSqm.toString(),
      '\$${widget.order.totalPrice.toString()}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canAcceptReject = OrderLifecyclePolicy.canAcceptReject(widget.order);
    final canStartTravel = OrderLifecyclePolicy.canStartTravel(widget.order);
    final canCancel = OrderLifecyclePolicy.canCancel(widget.order);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.pop(),
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              12.horizontalSpace,
              Expanded(
                child: AppText.headlineMedium(
                  'تفاصيل الطلب ${widget.order.bookingNumber}',
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
          Expanded(
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
                        spacing: 30,
                        children: List.generate(
                          3,
                          (i) => Expanded(
                            child: Column(
                              children: [
                                AppText.headlineMedium(
                                  val[i],
                                  color: context.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                SizedBox(height: 8),
                                AppText.labelLarge(
                                  titles[i],
                                  color: context.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  OrderInfoCard(order: widget.order),
                  SizedBox(height: 14),
                  EstateInfoCard(order: widget.order),
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
