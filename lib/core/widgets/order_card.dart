import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/cancel_order_dialog.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_travel_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/orders/view/screens/order_details_screen.dart';
import '../../generated/assets.dart';
import '../../features/orders/data/models/fetch_orders_usecase_model.dart';

enum OrderStatus { workerAssigned, inProgress }

class OrderCard extends StatefulWidget {
  const OrderCard({super.key, required this.date, this.orderStatus = OrderStatus.workerAssigned, this.isInHome = false, required this.bloc});

  final FetchOrdersUsecaseModelDataItem date;

  final OrderStatus orderStatus;

  final bool isInHome;

  final OrdersBloc bloc;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  List<String> attributes = [];

  @override
  void initState() {
    super.initState();
    attributes = [
      '${widget.date.propertyDetails?.bathrooms} حمام',
      '${widget.date.propertyDetails?.bedRooms} غرف نوم',
      if (widget.date.propertyDetails?.kitchen == true) 'مطبخ',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.pushRoute(
          '/orderdetails',
          arguments: OrderDetailsScreenParams(isNewOrder: widget.isInHome, order: widget.date, bloc: widget.bloc),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.onPrimary,
          border: Border(right: BorderSide(color: context.primaryContainer, width: 5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
                    child: AppText.labelLarge(widget.date.locationName ?? '', fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 12),
                  Divider(height: 1, color: context.surface),
                  SizedBox(height: 12),
                  dataRow(Assets.imagesOrderCardCalender, 'جدولة الحجز', widget.date.scheduledDate ?? ''),
                  SizedBox(height: 12),
                  dataRow(
                    Assets.imagesOrderCardAlarm,
                    'موعد الخدمة',
                    widget.date.scheduledTime == null ? '' : DateFormat('hh:mm a').format(DateFormat("HH:mm:ss").parse(widget.date.scheduledTime!)),
                  ),
                  SizedBox(height: 12),
                  Divider(height: 1, color: context.surface),
                  SizedBox(height: 12),
                  dataRow(Assets.imagesOrderCardBuilding, 'نوع العقار', widget.date.propertyType ?? ''),
                  SizedBox(height: 12),
                  dataRow(
                    Assets.imagesOrderCardAlarm,
                    'المساحة التقديرية',
                    widget.date.estimatedSqm == null ? '' : '${widget.date.estimatedSqm} متر مربع',
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 35,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsetsDirectional.symmetric(vertical: 5),
                      itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(
                          color: Color(0xffCAC7FF),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(63), blurRadius: 2, offset: Offset(0, 2))],
                        ),
                        padding: EdgeInsetsDirectional.symmetric(horizontal: 22, vertical: 3),
                        child: AppText.labelMedium(attributes[index], color: context.primary, fontWeight: FontWeight.w300),
                      ),
                      separatorBuilder: (context, index) => SizedBox(width: 10),
                      itemCount: attributes.length,
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
                    child: widget.orderStatus == OrderStatus.inProgress
                        ? Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: BlocBuilder<OrdersBloc, OrdersState>(
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: () {
                                        context.read<OrdersBloc>().add(
                                          StartTravelUsecaseEvent(params: StartTravelUsecaseParams(id: widget.date.id!)),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: widget.isInHome ? context.primaryContainer : context.primary,
                                        ),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
                                        child: AppText.labelLarge('أنا في الطريق', color: context.onPrimary, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () {
                                    CancelOrderDialog.show(
                                      context,
                                      bloc: widget.bloc,
                                      orderId: widget.date.id!,
                                      orderNum: widget.date.bookingNumber!,
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.error.withAlpha(50),
                                      border: Border.all(color: context.error),
                                    ),
                                    padding: EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 8),
                                    child: AppText.labelLarge('إلغاء الطلب', color: context.error, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: widget.isInHome ? context.primaryContainer : context.primary,
                                  ),
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
                                  child: AppText.labelLarge('قبول الطلب', color: context.onPrimary, fontWeight: FontWeight.w500),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: BlocBuilder<OrdersBloc, OrdersState>(
                                  bloc: widget.bloc,
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: () {
                                        context.read<OrdersBloc>().add(
                                          RejectOrderUsecaseEvent(params: RejectOrderUsecaseParams(id: widget.date.id!)),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: context.error.withAlpha(50),
                                          border: Border.all(color: context.error),
                                        ),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 8),
                                        child: state.rejectOrderUsecaseStatus == BlocStatus.loading
                                            ? Center(
                                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.error)),
                                              )
                                            : AppText.labelLarge('رفض', color: context.error, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(14), bottomRight: Radius.circular(10)),
                        color: widget.isInHome ? context.primary.withAlpha(51) : context.primaryContainer.withAlpha(51),
                      ),
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 22, vertical: 8),
                      child: AppText.bodyLarge(
                        '${widget.date.totalPrice.toString()} ل.س',
                        fontWeight: FontWeight.w500,
                        color: widget.isInHome ? context.primary : context.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget dataRow(image, title, data) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
      child: Row(
        children: [
          AppImage.asset(image, size: 15),
          SizedBox(width: 8),
          AppText.labelMedium(title, fontWeight: FontWeight.w300),
          Spacer(),
          AppText.labelMedium(data, fontWeight: FontWeight.w300),
        ],
      ),
    );
  }
}
