import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/cancel_order_dialog.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_travel_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/accept_order_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.data,
    required this.bloc,
    required this.index,
  });

  final FetchOrdersUsecaseModelDataItem data;
  final OrdersBloc bloc;
  final int index;

  String _serviceName() {
    final type = (data.propertyType ?? '').toLowerCase();
    switch (type) {
      case 'apartment':
        return 'خدمة تنظيف شقة';
      case 'house':
        return 'خدمة تنظيف منزل';
      case 'villa':
        return 'خدمة تنظيف فيلا';
      case 'studio':
        return 'خدمة تنظيف ستوديو';
      default:
        return 'خدمة تنظيف منزل';
    }
  }

  String _statusLabel() => OrderLifecyclePolicy.statusLabel(data);

  Color _statusColor(BuildContext context) {
    final status = data.status;
    if (status == CleaningBookingStatus.pending) return const Color(0xff1E2A78);
    if (status == CleaningBookingStatus.workerAssigned) {
      return const Color(0xff0EA5E9);
    }
    if (status == CleaningBookingStatus.awaitingStartVerification) {
      return const Color(0xffF59E0B);
    }
    if (status == CleaningBookingStatus.inProgress ||
        status == CleaningBookingStatus.timeExtensionRequested) {
      return context.primaryContainer;
    }
    if (status == CleaningBookingStatus.awaitingCustomerCompletion) {
      return const Color(0xff6366F1);
    }
    if (status == CleaningBookingStatus.completed) {
      return const Color(0xff10B981);
    }
    return const Color(0xff64748B);
  }

  String _formatDate() {
    final raw = data.scheduledDate;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}_${parsed.month}_${parsed.day}';
  }

  String _formatTime() {
    final raw = data.scheduledTime;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse('2000-01-01T$raw');
    if (parsed == null) return raw;
    return DateFormat('h:mm a').format(parsed).toLowerCase();
  }

  List<String> _attributeLabels() {
    final labels = <String>[];
    final baths = data.propertyDetails?.bathrooms;
    final beds = data.propertyDetails?.bedRooms;
    final kitchen = data.propertyDetails?.kitchen;
    if (baths != null) labels.add('$baths حمام');
    if (beds != null) labels.add('$beds غرف نوم');
    if (kitchen != null) labels.add('مطبخ');
    return labels;
  }

  void _openDetails(BuildContext context) {
    context.pushRoute(
      '/orderdetails',
      arguments: OrderDetailsScreenParams(
        isNewOrder: OrderLifecyclePolicy.isPending(data),
        order: data,
        bloc: bloc,
        index: index,
      ),
    );
  }

  Widget _metaTile({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  title,
                  color: const Color(0xff6B7280),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 4),
                AppText.bodyMedium(value, fontWeight: FontWeight.w700),
              ],
            ),
          ),
          Icon(icon, color: context.primaryContainer, size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final attributes = _attributeLabels();
    final bookingLabel = data.bookingNumber ?? '${data.id ?? '-'}';

    return InkWell(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 3.5, backgroundColor: statusColor),
                      const SizedBox(width: 6),
                      AppText.labelSmall(
                        _statusLabel(),
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff334155),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xffCBD5E1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleSmall(
                        _serviceName(),
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 4),
                      AppText.bodySmall(
                        '#ORD-$bookingLabel • منذ 2 دقيقة',
                        color: const Color(0xff6B7280),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText.titleSmall(
                      '${data.totalPrice ?? 0} ل.س',
                      color: const Color(0xff1E2A78),
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: context.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: AppText.labelSmall(
                        'نقدي',
                        color: context.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _metaTile(
              context: context,
              title: 'جدولة الحجز',
              value: _formatDate(),
              icon: Icons.calendar_today_rounded,
            ),
            const SizedBox(height: 8),
            _metaTile(
              context: context,
              title: 'موعد الخدمة',
              value: _formatTime(),
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 8),
            _metaTile(
              context: context,
              title: 'المساحة التقديرية',
              value: '${data.estimatedSqm ?? '-'} متر مربع',
              icon: Icons.square_foot_rounded,
            ),
            if (attributes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attributes
                    .map(
                      (label) => Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.primaryContainer.withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AppText.bodySmall(
                          label,
                          color: context.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (OrderLifecyclePolicy.canAcceptReject(data))
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BlocBuilder<OrdersBloc, OrdersState>(
                      bloc: bloc,
                      builder: (context, state) {
                        final loading =
                            OrderLifecyclePolicy.isLoadingForOrderIndex(
                              state: state,
                              orderIndex: index,
                              actionStatus: state.acceptOrderUsecaseStatus,
                            );
                        return InkWell(
                          onTap: loading
                              ? null
                              : () {
                                  AcceptOrderBottomSheet.show(
                                    context,
                                    order: data,
                                    bloc: bloc,
                                    index: index,
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
                              child: loading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.onPrimary,
                                      ),
                                    )
                                  : AppText.labelLarge(
                                      'قبول الطلب',
                                      color: context.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (data.status != CleaningBookingStatus.pending) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: BlocBuilder<OrdersBloc, OrdersState>(
                        bloc: bloc,
                        builder: (context, state) {
                          final loading =
                              OrderLifecyclePolicy.isLoadingForOrderIndex(
                                state: state,
                                orderIndex: index,
                                actionStatus: state.cancelOrderStatus,
                              );
                          return InkWell(
                            onTap: loading
                                ? null
                                : () {
                                    if (data.id == null) return;
                                    CancelOrderDialog.show(
                                      context,
                                      bloc: bloc,
                                      orderId: data.id!,
                                      orderNum:
                                          data.bookingNumber ?? bookingLabel,
                                      index: index,
                                    );
                                  },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: context.error.withAlpha(20),
                                border: Border.all(color: context.error),
                              ),
                              child: Center(
                                child: loading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.error,
                                        ),
                                      )
                                    : AppText.labelLarge(
                                        'إلغاء',
                                        color: context.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              )
            else if (OrderLifecyclePolicy.canStartTravel(data))
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BlocBuilder<OrdersBloc, OrdersState>(
                      bloc: bloc,
                      builder: (context, state) {
                        final loading =
                            OrderLifecyclePolicy.isLoadingForOrderIndex(
                              state: state,
                              orderIndex: index,
                              actionStatus: state.startTravelUsecaseStatus,
                            );
                        return InkWell(
                          onTap: loading
                              ? null
                              : () {
                                  if (data.id == null) return;
                                  bloc.add(
                                    StartTravelUsecaseEvent(
                                      params: StartTravelUsecaseParams(
                                        id: data.id!,
                                      ),
                                      index: index,
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
                              child: loading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.onPrimary,
                                      ),
                                    )
                                  : AppText.labelLarge(
                                      'أنا في الطريق',
                                      color: context.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: OrderLifecyclePolicy.canCancel(data)
                          ? () {
                              CancelOrderDialog.show(
                                context,
                                bloc: bloc,
                                orderId: data.id!,
                                orderNum: data.bookingNumber!,
                                index: index,
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: context.error.withAlpha(20),
                          border: Border.all(color: context.error),
                        ),
                        child: Center(
                          child: AppText.labelLarge(
                            'إلغاء',
                            color: context.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: () => _openDetails(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.primaryContainer,
                  ),
                  child: Center(
                    child: AppText.labelLarge(
                      'متابعة الطلب',
                      color: context.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
