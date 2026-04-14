import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/cancel_order_dialog.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/arrive_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_travel_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../features/orders/view/screens/order_details_screen.dart';
import '../../generated/assets.dart';
import '../../features/orders/data/models/fetch_orders_usecase_model.dart';

enum OrderStatus { workerAssigned, pending, inProgress }

class OrderCard extends StatefulWidget {
  const OrderCard({
    super.key,
    required this.date,
    this.orderStatus = OrderStatus.workerAssigned,
    this.isInHome = false,
    required this.bloc,
    required this.index,
  });

  final FetchOrdersUsecaseModelDataItem date;

  final OrderStatus orderStatus;

  final bool isInHome;

  final OrdersBloc bloc;

  final int index;

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
          arguments: OrderDetailsScreenParams(
            isNewOrder: widget.orderStatus == OrderStatus.workerAssigned,
            order: widget.date,
            bloc: widget.bloc,
            index: widget.index,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: context.onPrimary,
          border: Border(
            right: BorderSide(color: context.primaryContainer, width: 5.w),
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                    child: AppText.labelLarge(widget.date.locationName ?? '', fontWeight: FontWeight.w400),
                  ),
                  12.verticalSpace,
                  Divider(height: 1.h, color: context.surface),
                  12.verticalSpace,
                  dataRow(Assets.images.orderCardCalender.path, 'جدولة الحجز', widget.date.scheduledDate ?? ''),
                  12.verticalSpace,
                  dataRow(
                    Assets.images.orderCardAlarm.path,
                    'موعد الخدمة',
                    widget.date.scheduledTime == null ? '' : DateFormat('hh:mm a').format(DateFormat("HH:mm:ss").parse(widget.date.scheduledTime!)),
                  ),
                  12.verticalSpace,
                  Divider(height: 1.h, color: context.surface),
                  12.verticalSpace,
                  dataRow(Assets.images.orderCardBuilding.path, 'نوع العقار', widget.date.propertyType ?? ''),
                  12.verticalSpace,
                  dataRow(
                    Assets.images.orderCardPointer.path,
                    'المساحة التقديرية',
                    widget.date.estimatedSqm == null ? '' : '${widget.date.estimatedSqm} متر مربع',
                  ),
                  12.verticalSpace,
                  Container(
                    height: 35.h,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsetsDirectional.symmetric(vertical: 5.h),
                      itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(
                          color: Color(0xffCAC7FF),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(63), blurRadius: 2.r, offset: Offset(0, 2.h))],
                        ),
                        padding: EdgeInsetsDirectional.symmetric(horizontal: 22.w, vertical: 3.h),
                        child: AppText.labelMedium(attributes[index], color: context.primary, fontWeight: FontWeight.w300),
                      ),
                      separatorBuilder: (context, index) => 10.horizontalSpace,
                      itemCount: attributes.length,
                    ),
                  ),
                  12.verticalSpace,
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
                    child: widget.orderStatus == OrderStatus.workerAssigned
                        ? Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: BlocBuilder<OrdersBloc, OrdersState>(
                                  bloc: widget.bloc,
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: () {
                                        widget.bloc.add(
                                          StartTravelUsecaseEvent(
                                            params: StartTravelUsecaseParams(id: widget.date.id!),
                                            index: widget.index,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          color: widget.isInHome ? context.primaryContainer : context.primary,
                                        ),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w, vertical: 8.h),
                                        child: state.startTravelUsecaseStatus == BlocStatus.loading && state.selectedIndex == widget.index
                                            ? Center(
                                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.onPrimary)),
                                              )
                                            : AppText.labelLarge('أنا في الطريق', color: context.onPrimary, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              8.horizontalSpace,
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
                                      borderRadius: BorderRadius.circular(8.r),
                                      color: context.error.withAlpha(50),
                                      border: Border.all(color: context.error),
                                    ),
                                    padding: EdgeInsetsDirectional.symmetric(horizontal: 6.w, vertical: 8.h),
                                    child: AppText.labelLarge('إلغاء الطلب', color: context.error, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : widget.orderStatus == OrderStatus.inProgress
                        ? Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: BlocBuilder<OrdersBloc, OrdersState>(
                                  bloc: widget.bloc,
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: () {
                                        widget.bloc.add(
                                          ArriveEvent(
                                            params: ArriveParams(id: widget.date.id!),
                                            index: widget.index,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          color: widget.isInHome ? context.primaryContainer : context.primary,
                                        ),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w, vertical: 8.h),
                                        child: state.arriveStatus == BlocStatus.loading && state.selectedIndex == widget.index
                                            ? Center(
                                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.onPrimary)),
                                              )
                                            : AppText.labelLarge('لقد وصلت', color: context.onPrimary, fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              BlocBuilder<OrdersBloc, OrdersState>(
                                bloc: widget.bloc,
                                builder: (context, state) {
                                  return Expanded(
                                    flex: 5,
                                    child: InkWell(
                                      onTap: () {
                                        context.read<OrdersBloc>().add(
                                          AcceptOrderUsecaseEvent(
                                            params: AcceptOrderUsecaseParams(id: widget.date.id!),
                                            index: widget.index,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          color: widget.isInHome ? context.primaryContainer : context.primary,
                                        ),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w, vertical: 8.h),
                                        child: state.acceptOrderUsecaseStatus == BlocStatus.loading && state.selectedIndex == widget.index
                                            ? Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(color: context.onPrimaryContainer),
                                                ),
                                              )
                                            : AppText.labelLarge('قبول الطلب', color: context.onPrimary, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              8.horizontalSpace,
                              Expanded(
                                flex: 2,
                                child: BlocBuilder<OrdersBloc, OrdersState>(
                                  bloc: widget.bloc,
                                  builder: (context, state) {
                                    return InkWell(
                                      onTap: () {
                                        context.read<OrdersBloc>().add(
                                          RejectOrderUsecaseEvent(
                                            params: RejectOrderUsecaseParams(id: widget.date.id!),
                                            index: widget.index,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          color: context.error.withAlpha(50),
                                          border: Border.all(color: context.error),
                                        ),
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 6.w, vertical: 8.h),
                                        child: state.rejectOrderUsecaseStatus == BlocStatus.loading && state.selectedIndex == widget.index
                                            ? Center(
                                                child: SizedBox(
                                                  width: 20.w,
                                                  height: 20.h,
                                                  child: CircularProgressIndicator(color: context.error),
                                                ),
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
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(14.r), bottomRight: Radius.circular(10.r)),
                        color: widget.isInHome ? context.primary.withAlpha(51) : context.primaryContainer.withAlpha(51),
                      ),
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 22.w, vertical: 8.h),
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
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          SizedBox(width: 20, child: AppImage.asset(image, size: 15.r)),
          8.horizontalSpace,
          AppText.labelMedium(title, fontWeight: FontWeight.w300),
          Spacer(),
          AppText.labelMedium(data, fontWeight: FontWeight.w300),
        ],
      ),
    );
  }
}
