import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/estate_info_card.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_info_card.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/payment_info_card.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/cancel_order_dialog.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../../domain/usecases/reject_order_usecase_use_case.dart';
import '../../domain/usecases/start_travel_usecase_use_case.dart';
import '../manager/bloc/orders_bloc.dart';

@AutoRoutePage()
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.params});

  final OrderDetailsScreenParams params;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<String> titles = ['إجمالي عدد\nساعات العمل', 'المساحة\nالتقديرية', 'السعر\nالإجمالي'];
  List<String> val = [];

  @override
  void initState() {
    super.initState();
    val = [widget.params.order.totalHours.toString(), widget.params.order.estimatedSqm.toString(), '\$${widget.params.order.totalPrice.toString()}'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: AppText.headlineMedium('تفاصيل الطلب ${widget.params.order.bookingNumber}', textAlign: TextAlign.start)),
                  InkWell(
                    onTap: () {
                      context.pop();
                    },
                    child: Icon(Icons.arrow_forward, color: Colors.black),
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
                      OrderInfoCard(order: widget.params.order),
                      SizedBox(height: 14),
                      EstateInfoCard(order: widget.params.order),
                      SizedBox(height: 14),
                      PaymentInfoCard(order: widget.params.order),
                      SizedBox(height: 10),
                      !widget.params.isNewOrder
                          ? Column(
                              children: [
                                BlocBuilder<OrdersBloc, OrdersState>(
                                  bloc: widget.params.bloc,
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: () {
                                        context.read<OrdersBloc>().add(
                                          StartTravelUsecaseEvent(params: StartTravelUsecaseParams(id: widget.params.order.id!)),
                                        );
                                      },
                                      child: Container(
                                        width: context.width,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primary),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                                        child: AppText.labelLarge('أنا في الطريق', color: context.onPrimary, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 12),
                                InkWell(
                                  onTap: () {
                                    CancelOrderDialog.show(
                                      context,
                                      bloc: widget.params.bloc,
                                      orderId: widget.params.order.id!,
                                      orderNum: widget.params.order.bookingNumber!,
                                    );
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
                                Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primary),
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                                  width: context.width,
                                  child: AppText.labelLarge('قبول الطلب', color: context.onPrimary, fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 12),
                                BlocBuilder<OrdersBloc, OrdersState>(
                                  bloc: widget.params.bloc,
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: () {
                                        context.read<OrdersBloc>().add(
                                          RejectOrderUsecaseEvent(params: RejectOrderUsecaseParams(id: widget.params.order.id!)),
                                        );
                                      },
                                      child: Container(
                                        width: context.width,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: context.error,
                                          border: Border.all(color: context.error),
                                        ),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 14),
                                        child: state.rejectOrderUsecaseStatus == BlocStatus.loading
                                            ? Center(
                                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.error)),
                                              )
                                            : AppText.labelLarge('رفض', color: context.onError, fontWeight: FontWeight.w500),
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
        ),
      ),
    );
  }
}

class OrderDetailsScreenParams {
  final FetchOrdersUsecaseModelDataItem order;

  final bool isNewOrder;

  final OrdersBloc bloc;

  OrderDetailsScreenParams({required this.order, required this.isNewOrder, required this.bloc});
}
