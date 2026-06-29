import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/extentions.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/cancel_order_dialog.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_relative_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_travel_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/event_assistance_order_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/accept_order_bottom_sheet.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/extension_request_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:injectable/injectable.dart';

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

  bool get _isEventAssistance =>
      EventAssistanceOrderHelper.isEventAssistance(data.propertyType);

  String _serviceName() {
    return EventAssistanceOrderHelper.serviceTitle(
      propertyType: data.propertyType,
      customService: data.propertyDetails?.customService,
    );
  }

  String _statusLabel() => OrderLifecyclePolicy.statusLabel(data);

  Color _statusColor(BuildContext context) {
    if (OrderLifecyclePolicy.isAcceptedWaiting(data)) {
      return const Color(0xff0EA5E9);
    }
    final status = data.status;
    if (status == CleaningBookingStatus.pending) return const Color(0xff1E2A78);
    if (status == CleaningBookingStatus.workerAssigned) {
      return const Color(0xff0EA5E9);
    }
    if (status == CleaningBookingStatus.awaitingStartVerification) {
      return const Color(0xffF59E0B);
    }
    if (status == CleaningBookingStatus.awaitingWorkerStartConfirmation) {
      return const Color(0xff059669);
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

  Widget _acceptedWaitingBanner(BuildContext context) {
    // 1. التحقق الأساسي من الحالة
    if (!OrderLifecyclePolicy.isAcceptedWaiting(data)) {
      return const SizedBox.shrink();
    }

    // 2. الحصول على الرسالة (التي قد تكون null)
    final String? message = OrderLifecyclePolicy.acceptedWaitingMessage(data);

    // 3. إذا كانت الرسالة null، نقوم بإخفاء الـ Banner تماماً
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    // 4. عرض الـ Banner فقط إذا كانت هناك رسالة حقيقية
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffE0F2FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff7DD3FC)),
      ),
      child: AppText.labelMedium(
        message, // الآن نحن متأكدون أنها ليست null
        color: const Color(0xff075985),
        fontWeight: FontWeight.w700,
        textAlign: TextAlign.start,
      ),
    );
  }

  String _formatDate() {
    final raw = data.scheduledDate;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year} / ${parsed.month} / ${parsed.day}';
  }

  String _formatTime() {
    return CleaningArabicTimeFormatter.formatFromScheduledTimeField(
      data.scheduledTime,
      pattern: 'h:mm a',
    );
  }

  String _createdAtHumanReadable() {
    return CleaningRelativeTimeFormatter.fromBackendCreatedAt(data.createdAt);
  }

  String _bookingSubtitle(String bookingLabel) {
    final createdAtLabel = _createdAtHumanReadable();
    if (createdAtLabel.isEmpty) return '#ORD-$bookingLabel';
    return '#ORD-$bookingLabel \n• $createdAtLabel';
  }

  // List<String> _attributeLabels() {
  //   if (_isEventAssistance) {
  //     final labels = <String>[];
  //     final guests = data.propertyDetails?.guestCount;
  //     final venue = data.propertyDetails?.venueType;
  //     final hours = EventAssistanceOrderHelper.resolveBookedHours(
  //       propertyHours: data.propertyDetails?.hours,
  //       totalHours: data.totalHours,
  //       estimatedHours: data.estimatedHours,
  //     );
  //     if (guests != null) labels.add('$guests ضيف');
  //     if (venue != null && venue.isNotEmpty) {
  //       labels.add(EventAssistanceOrderHelper.venueTypeLabelAr(venue));
  //     }
  //     if (hours != null) {
  //       labels.add(EventAssistanceOrderHelper.formatHours(hours));
  //     }
  //     return labels;
  //   }
  //
  //   final labels = <String>[];
  //   final baths = data.propertyDetails?.bathrooms;
  //   final beds = data.propertyDetails?.bedRooms;
  //   final kitchen = data.propertyDetails?.kitchen;
  //   if (baths != null) labels.add('$baths حمام');
  //   if (beds != null) labels.add('$beds غرف نوم');
  //   if (kitchen != null) labels.add('مطبخ');
  //   return labels;
  // }

  void _openDetails(BuildContext context) {
    if (OrderLifecyclePolicy.isTimeExtensionRequested(data)) {
      unawaited(_openExtensionRequestActionSheet(context));
      return;
    }
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

  Future<void> _openExtensionRequestActionSheet(BuildContext context) async {
    final request =
        _resolveExtensionRequest() ??
        await _fetchAndResolveExtensionRequest(context);
    if (!context.mounted) return;
    if (request == null) {
      AppToast.showErrorGlobal('تعذر فتح طلب تمديد الوقت حالياً');
      return;
    }
    ExtensionRequestActionSheet.show(
      context,
      bloc: bloc,
      warningId: request.warningId,
      bookingId: request.bookingId ?? data.id,
      requestedMinutes: request.requestedMinutes,
      customerName: request.customerName ?? data.customer?.name,
      additionalAmount: request.additionalAmount,
      currency: request.currency,
      paymentMethod: request.paymentMethod,
    );
  }

  Future<_CardExtensionRequest?> _fetchAndResolveExtensionRequest(
    BuildContext context,
  ) async {
    final bookingId = data.id;
    if (bookingId == null) return null;

    bloc.add(
      FetchExtensionRequestsUsecasEvent(
        params: FetchExtensionRequestsUsecasParams(),
        isReload: true,
      ),
    );

    final completedState = await bloc.stream.firstWhere((state) {
      final status = state.extensionRequestsUsecas?.status;
      return status != BlocStatus.loading;
    });
    if (!context.mounted) return null;

    return _resolveExtensionRequestFromFetchedRequests(completedState);
  }

  _CardExtensionRequest? _resolveExtensionRequestFromFetchedRequests(
    OrdersState state,
  ) {
    final bookingId = data.id;
    if (bookingId == null) return null;
    final requests = state.extensionRequestsUsecas?.list ?? const [];
    for (final request in requests) {
      if (request.bookingId != bookingId) continue;
      if (!request.isPendingWorkerResponse) continue;
      final warningId = request.id;
      if (warningId == null) continue;
      return _CardExtensionRequest(
        warningId: warningId,
        bookingId: request.bookingId,
        requestedMinutes: request.resolvedAdditionalMinutes,
        customerName: data.customer?.name,
      );
    }
    return null;
  }

  _CardExtensionRequest? _resolveExtensionRequest() {
    final warnings = data.timeWarnings ?? const <dynamic>[];
    for (final warning in warnings) {
      final map = _asStringMap(warning);
      if (map.isEmpty) continue;
      if (!_isPendingExtensionWarning(map)) continue;
      final warningId = _toInt(
        _pick(map, const <String>['id', 'warningId', 'warning_id']),
      );
      if (warningId == null) continue;
      return _CardExtensionRequest(
        warningId: warningId,
        bookingId: _toInt(
          _pick(map, const <String>[
            'bookingId',
            'booking_id',
            'cleaningBookingId',
            'cleaning_booking_id',
          ]),
        ),
        requestedMinutes: _toInt(
          _pick(map, const <String>[
            'additionalMinutes',
            'additional_minutes',
            'requestedMinutes',
            'requested_minutes',
          ]),
        ),
        customerName: _toStringValue(
          _pick(map, const <String>['customerName', 'customer_name']) ??
              _pick(_asStringMap(map['customer']), const <String>['name']),
        ),
        additionalAmount: _toDouble(
          _pick(map, const <String>[
            'additionalAmount',
            'additional_amount',
            'amount',
          ]),
        ),
        currency: _toStringValue(_pick(map, const <String>['currency'])),
        paymentMethod: _toStringValue(
          _pick(map, const <String>['paymentMethod', 'payment_method']),
        ),
      );
    }
    return null;
  }

  bool _isPendingExtensionWarning(Map<String, dynamic> map) {
    final responseStatus = _toStringValue(
      _pick(map, const <String>['responseStatus', 'response_status', 'status']),
    )?.trim().toLowerCase();
    if (responseStatus == 'accepted' ||
        responseStatus == 'rejected' ||
        responseStatus == 'resolved' ||
        responseStatus == 'closed') {
      return false;
    }
    final workerResponse = _toStringValue(
      _pick(map, const <String>['workerResponse', 'worker_response']),
    )?.trim().toLowerCase();
    if (workerResponse == 'accept' ||
        workerResponse == 'accepted' ||
        workerResponse == 'reject' ||
        workerResponse == 'rejected' ||
        workerResponse == 'commit_current_time') {
      return false;
    }
    final respondedAt = _toStringValue(
      _pick(map, const <String>['workerRespondedAt', 'worker_responded_at']),
    );
    return respondedAt == null || respondedAt.trim().isEmpty;
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
                AppText.labelMedium(
                  title,
                  color: const Color(0xff6B7280),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 4),
                AppText.labelSmall(value, fontWeight: FontWeight.w700),
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
                      AppText.labelSmall(
                        _bookingSubtitle(bookingLabel),
                        color: const Color(0xff6B7280),
                        textAlign: TextAlign.start,
                      ),
                      if (data.displayNeighborhoodName != null) ...[
                        const SizedBox(height: 4),
                        AppText.labelSmall(
                          'الحي: ${data.displayNeighborhoodName}',
                          color: const Color(0xff475569),
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                          CircleAvatar(
                            radius: 3.5,
                            backgroundColor: statusColor,
                          ),
                          const SizedBox(width: 6),
                          AppText.labelSmall(
                            _statusLabel(),
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText.titleSmall(
                      data.totalPrice.formatMoney(),
                      color: const Color(0xff1E2A78),
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),

                    isSameDate(data.createdAt,data.scheduledDate)
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

                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: context.primaryContainer,
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   padding: const EdgeInsetsDirectional.symmetric(
                    //     horizontal: 12,
                    //     vertical: 5,
                    //   ),
                    //   child: AppText.labelSmall(
                    //     'نقدي',
                    //     color: context.onPrimaryContainer,
                    //     fontWeight: FontWeight.w700,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _metaTile(
                    context: context,
                    title: 'جدولة الحجز',
                    value: _formatDate(),
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metaTile(
                    context: context,
                    title: 'موعد الخدمة',
                    value: _formatTime(),
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (OrderLifecyclePolicy.isAcceptedWaiting(data)) ...[
              const SizedBox(height: 10),
              _acceptedWaitingBanner(context),
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
                                  : AppText.labelMedium(
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: BlocBuilder<OrdersBloc, OrdersState>(
                      bloc: bloc,
                      builder: (context, state) {
                        final isPending =
                            data.status == CleaningBookingStatus.pending;
                        final loading =
                            OrderLifecyclePolicy.isLoadingForOrderIndex(
                              state: state,
                              orderIndex: index,
                              actionStatus: isPending
                                  ? state.rejectOrderUsecaseStatus
                                  : state.cancelOrderStatus,
                            );
                        return InkWell(
                          onTap: loading
                              ? null
                              : () {
                                  if (data.id == null) return;
                                  if (isPending) {
                                    bloc.add(
                                      RejectOrderUsecaseEvent(
                                        params: RejectOrderUsecaseParams(
                                          id: data.id!,
                                        ),
                                        index: index,
                                      ),
                                    );
                                    return;
                                  }
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
                                  : AppText.labelMedium(
                                      isPending ? 'رفض' : 'إلغاء',
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
                                  if (!OrderLifecyclePolicy.isStartTravelWithinAllowedWindow(
                                    data,
                                  )) {
                                    AppToast.showErrorGlobal(
                                      OrderLifecyclePolicy
                                          .startTravelUnavailableMessage,
                                    );
                                    return;
                                  }
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
                                  : AppText.labelMedium(
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
                          child: AppText.labelMedium(
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
                onTap: () {
                  if (OrderLifecyclePolicy.isTimeExtensionRequested(data)) {
                    unawaited(_openExtensionRequestActionSheet(context));
                    return;
                  }
                  _openDetails(context);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.primaryContainer,
                  ),
                  child: Center(
                    child: AppText.labelMedium(
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

class _CardExtensionRequest {
  const _CardExtensionRequest({
    required this.warningId,
    this.bookingId,
    this.requestedMinutes,
    this.customerName,
    this.additionalAmount,
    this.currency,
    this.paymentMethod,
  });

  final int warningId;
  final int? bookingId;
  final int? requestedMinutes;
  final String? customerName;
  final double? additionalAmount;
  final String? currency;
  final String? paymentMethod;
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String? _toStringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
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