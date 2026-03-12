import 'package:common_package/common_package.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../../core/widgets/cancel_order_dialog.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../../domain/usecases/accept_order_usecase_use_case.dart';
import '../../../domain/usecases/reject_order_usecase_use_case.dart';
import '../../../domain/usecases/start_travel_usecase_use_case.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../estate_info_card.dart';
import '../order_info_card.dart';
import '../payment_info_card.dart';

class OrderDetailsBody extends StatefulWidget {
  const OrderDetailsBody({super.key, required this.bloc, required this.index, required this.order, required this.isNewOrder});

  final OrdersBloc bloc;
  final int index;
  final FetchOrdersUsecaseModelDataItem order;
  final bool isNewOrder;

  @override
  State<OrderDetailsBody> createState() => _OrderDetailsBodyState();
}

class _OrderDetailsBodyState extends State<OrderDetailsBody> {
  List<String> titles = ['إجمالي عدد\nساعات العمل', 'المساحة\nالتقديرية', 'السعر\nالإجمالي'];
  List<String> val = [];

  @override
  void initState() {
    super.initState();
    val = [widget.order.totalHours.toString(), widget.order.estimatedSqm.toString(), '\$${widget.order.totalPrice.toString()}'];
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: () {
                  context.pop();
                },
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              12.horizontalSpace,
              Expanded(child: AppText.headlineMedium('تفاصيل الطلب ${widget.order.bookingNumber}', textAlign: TextAlign.start)),
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
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primaryContainer.withAlpha(31)),
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 16),
                      child: Row(
                        spacing: 30,
                        children: List.generate(
                          3,
                          (i) => Expanded(
                            child: Column(
                              children: [
                                AppText.headlineMedium(val[i], color: context.primary, fontWeight: FontWeight.w500),
                                SizedBox(height: 8),
                                AppText.labelLarge(titles[i], color: context.primary, fontWeight: FontWeight.w500),
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
                  !widget.isNewOrder
                      ? Column(
                          children: [
                            BlocBuilder<OrdersBloc, OrdersState>(
                              bloc: widget.bloc,
                              builder: (context, state) {
                                return InkWell(
                                  onTap: () {
                                    widget.bloc.add(
                                      StartTravelUsecaseEvent(
                                        params: StartTravelUsecaseParams(id: widget.order.id!),
                                        index: widget.index,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: context.width,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primary),
                                    padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                                    child: state.startTravelUsecaseStatus == BlocStatus.loading
                                        ? Center(
                                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.onPrimary)),
                                          )
                                        : AppText.labelLarge('أنا في الطريق', color: context.onPrimary, fontWeight: FontWeight.w500),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                CancelOrderDialog.show(context, bloc: widget.bloc, orderId: widget.order.id!, orderNum: widget.order.bookingNumber!);
                              },
                              child: Container(
                                width: context.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: context.error,
                                  border: Border.all(color: context.error),
                                ),
                                padding: EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 14),
                                child: AppText.labelLarge('إلغاء الطلب', color: context.onError, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            BlocBuilder<OrdersBloc, OrdersState>(
                              bloc: widget.bloc,
                              builder: (context, state) {
                                return InkWell(
                                  onTap: () {
                                    widget.bloc.add(
                                      AcceptOrderUsecaseEvent(
                                        params: AcceptOrderUsecaseParams(id: widget.order.id!),
                                        index: widget.index,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primary),
                                    padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                                    width: context.width,
                                    child: state.acceptOrderUsecaseStatus == BlocStatus.loading
                                        ? Center(
                                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.onPrimary)),
                                          )
                                        : AppText.labelLarge('قبول الطلب', color: context.onPrimary, fontWeight: FontWeight.w500),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 12),
                            BlocBuilder<OrdersBloc, OrdersState>(
                              bloc: widget.bloc,
                              builder: (context, state) {
                                return InkWell(
                                  onTap: () {
                                    widget.bloc.add(
                                      RejectOrderUsecaseEvent(
                                        params: RejectOrderUsecaseParams(id: widget.order.id!),
                                        index: widget.index,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: context.width,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Color(0xff727791),
                                      border: Border.all(color: Color(0xff727791)),
                                    ),
                                    padding: EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 14),
                                    child: state.rejectOrderUsecaseStatus == BlocStatus.loading
                                        ? Center(
                                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.onError)),
                                          )
                                        : AppText.labelLarge('رفض الطلب', color: context.onError, fontWeight: FontWeight.w500),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
