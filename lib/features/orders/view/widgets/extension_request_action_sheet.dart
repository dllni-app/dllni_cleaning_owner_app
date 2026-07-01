import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/extension_time_format_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExtensionRequestActionSheet {
  static Future<bool> show(
    BuildContext context, {
    required OrdersBloc bloc,
    required int warningId,
    int? bookingId,
    int? requestedMinutes,
    String? customerName,
    double? additionalAmount,
    String? currency,
    String? paymentMethod,
    bool useRootNavigator = false,
  }) async {
    final resolved = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: bloc,
          child: PopScope(
            canPop: false,
            child: _ExtensionRequestActionSheetBody(
              bloc: bloc,
              warningId: warningId,
              bookingId: bookingId,
              requestedMinutes: requestedMinutes,
              customerName: customerName,
              additionalAmount: additionalAmount,
              currency: currency,
              paymentMethod: paymentMethod,
            ),
          ),
        );
      },
    );
    return resolved ?? false;
  }

  static String paymentMethodLabel(String? paymentMethod) {
    final value = (paymentMethod ?? '').trim().toLowerCase();
    if (value == 'cash' || value == 'cash_on_delivery') return 'نقداً عند الاستلام';
    if (value == 'card') return 'دفع إلكتروني';
    if (value.isEmpty) return 'طريقة الدفع غير محددة';
    return paymentMethod!;
  }
}

class _ExtensionRequestActionSheetBody extends StatefulWidget {
  const _ExtensionRequestActionSheetBody({
    required this.bloc,
    required this.warningId,
    this.bookingId,
    this.requestedMinutes,
    this.customerName,
    this.additionalAmount,
    this.currency,
    this.paymentMethod,
  });

  final OrdersBloc bloc;
  final int warningId;
  final int? bookingId;
  final int? requestedMinutes;
  final String? customerName;
  final double? additionalAmount;
  final String? currency;
  final String? paymentMethod;

  @override
  State<_ExtensionRequestActionSheetBody> createState() =>
      _ExtensionRequestActionSheetBodyState();
}

class _ExtensionRequestActionSheetBodyState extends State<_ExtensionRequestActionSheetBody> {
  final _messageController = TextEditingController();
  String? _rejectError;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onReject() {
    setState(() => _rejectError = null);
    widget.bloc.add(
      RejectExtensionUsecaseEvent(
        params: RejectExtensionUsecaseParams(id: widget.warningId),
      ),
    );
  }

  void _onAccept() {
    setState(() => _rejectError = null);
    widget.bloc.add(
      AcceptExtensionUsecaseEvent(
        params: AcceptExtensionUsecaseParams(
          id: widget.warningId,
          additionalMinutes: widget.requestedMinutes,
        ),
      ),
    );
  }

  void _refreshBookingAfterDecision() {
    final bookingId = widget.bookingId;
    if (bookingId == null) return;
    widget.bloc.add(
      FetchOrderDetailsUsecaseEvent(
        params: FetchOrderDetailsUsecaseParams(id: bookingId),
      ),
    );
    for (final status in const <String>[
      CleaningBookingStatus.timeExtensionRequested,
      CleaningBookingStatus.inProgress,
      CleaningBookingStatus.workerAssigned,
      CleaningBookingStatus.awaitingCustomerCompletion,
      CleaningBookingStatus.completed,
    ]) {
      widget.bloc.add(
        FetchOrdersUsecaseEvent(
          params: FetchOrdersUsecaseParams(page: 1, status: status),
          isReload: true,
          silent: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerText = (widget.customerName?.trim().isNotEmpty ?? false)
        ? widget.customerName!.trim()
        : 'العميل';
    final durationText = formatExtensionDurationAr(widget.requestedMinutes);
    final amountText = widget.additionalAmount == null
        ? '-'
        : widget.additionalAmount!.toStringAsFixed(2);
    final currencyText = (widget.currency?.trim().isNotEmpty ?? false)
        ? widget.currency!.trim()
        : 'ل.س';
    final paymentText = ExtensionRequestActionSheet.paymentMethodLabel(widget.paymentMethod);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: BlocConsumer<OrdersBloc, OrdersState>(
        bloc: widget.bloc,
        listenWhen: (previous, current) {
          final acceptedNow = previous.acceptExtensionUsecaseStatus != BlocStatus.success &&
              current.acceptExtensionUsecaseStatus == BlocStatus.success;
          final rejectedNow = previous.rejectExtensionUsecaseStatus != BlocStatus.success &&
              current.rejectExtensionUsecaseStatus == BlocStatus.success;
          return acceptedNow || rejectedNow;
        },
        buildWhen: (previous, current) =>
            previous.acceptExtensionUsecaseStatus != current.acceptExtensionUsecaseStatus ||
            previous.rejectExtensionUsecaseStatus != current.rejectExtensionUsecaseStatus,
        listener: (context, state) {
          if (state.acceptExtensionUsecaseStatus == BlocStatus.success ||
              state.rejectExtensionUsecaseStatus == BlocStatus.success) {
            _refreshBookingAfterDecision();
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final isLoading = state.acceptExtensionUsecaseStatus == BlocStatus.loading ||
              state.rejectExtensionUsecaseStatus == BlocStatus.loading;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.titleMedium(
                            'طلب تمديد مدة العمل',
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 4),
                          AppText.bodySmall(
                            'إذا كان برنامجك يسمح هذا سيؤدي لمرابح أكثر',
                            textAlign: TextAlign.center,
                            color: const Color(0xff6B7280),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText.bodyMedium(
                          'العميل $customerText يطلب تمديد الخدمة $durationText',
                          color: const Color(0xff9A3412),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.info_outline, color: Color(0xffEA580C), size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText.bodyMedium(
                        'مرابحك الإضافية',
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xffE5E7EB)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.bodyLarge('$amountText $currencyText', fontWeight: FontWeight.w700),
                          AppText.bodyLarge('الإجمالي', fontWeight: FontWeight.w700),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xffF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText.bodySmall(
                                paymentText,
                                color: const Color(0xff374151),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.payments_outlined, color: Color(0xff22C55E), size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_rejectError != null) ...[
                  AppText.bodySmall(_rejectError!, color: context.error, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                ],
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _onReject,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xffEF4444)),
                            foregroundColor: const Color(0xffEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: AppText.labelLarge('رفض الطلب', color: const Color(0xffEF4444)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoading ? null : _onAccept,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff1DBCC8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading && state.acceptExtensionUsecaseStatus == BlocStatus.loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : AppText.labelLarge('قبول الطلب', color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
