import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_extension_requests_usecas_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/extension_time_format_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/worker_app_colors.dart';

class ExtensionRequestActionSheet {
  static Future<bool> show(
    BuildContext context, {
    required OrdersBloc bloc,
    required int warningId,
    int? bookingId,
    int? requestedMinutes,
    String? customerName,
    double? baseAmount,
    double? adminMargin,
    double? totalAmount,
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
              baseAmount: baseAmount,
              adminMargin: adminMargin,
              totalAmount: totalAmount,
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
    if (value == 'cash' || value == 'cash_on_delivery') {
      return 'نقداً عند الاستلام';
    }
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
    this.baseAmount,
    this.adminMargin,
    this.totalAmount,
    this.additionalAmount,
    this.currency,
    this.paymentMethod,
  });

  final OrdersBloc bloc;
  final int warningId;
  final int? bookingId;
  final int? requestedMinutes;
  final String? customerName;
  final double? baseAmount;
  final double? adminMargin;
  final double? totalAmount;
  final double? additionalAmount;
  final String? currency;
  final String? paymentMethod;

  @override
  State<_ExtensionRequestActionSheetBody> createState() =>
      _ExtensionRequestActionSheetBodyState();
}

class _ExtensionRequestActionSheetBodyState
    extends State<_ExtensionRequestActionSheetBody> {
  final _messageController = TextEditingController();
  String? _rejectError;
  bool _isSubmitting = false;
  _ExtensionDecision? _pendingDecision;
  bool _pendingDecisionStarted = false;

  @override
  void initState() {
    super.initState();
    // Fetch the latest quote when opening a push notification. The decision
    // endpoint validates the warning; missing breakdown fields do not block it.
    if (widget.warningId > 0) {
      widget.bloc.add(
        FetchExtensionRequestsUsecasEvent(
          params: FetchExtensionRequestsUsecasParams(),
          isReload: true,
        ),
      );
    }
  }

  FetchExtensionRequestsUsecasModelDataItem? _trustedWarning(
    OrdersState state,
  ) {
    for (final warning
        in state.extensionRequestsUsecas?.list ??
            const <FetchExtensionRequestsUsecasModelDataItem>[]) {
      if (warning.id == widget.warningId) {
        return warning;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onReject() {
    if (_isSubmitting) return;
    setState(() {
      _rejectError = null;
      _isSubmitting = true;
      _pendingDecision = _ExtensionDecision.reject;
      _pendingDecisionStarted = false;
    });
    widget.bloc.add(
      RejectExtensionUsecaseEvent(
        params: RejectExtensionUsecaseParams(id: widget.warningId),
      ),
    );
  }

  void _onAccept() {
    if (_isSubmitting) return;
    setState(() {
      _rejectError = null;
      _isSubmitting = true;
      _pendingDecision = _ExtensionDecision.accept;
      _pendingDecisionStarted = false;
    });
    widget.bloc.add(
      AcceptExtensionUsecaseEvent(
        params: AcceptExtensionUsecaseParams(
          id: widget.warningId,
          additionalMinutes:
              _trustedWarning(widget.bloc.state)?.resolvedAdditionalMinutes ??
              widget.requestedMinutes,
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
  }

  @override
  Widget build(BuildContext context) {
    final customerText = (widget.customerName?.trim().isNotEmpty ?? false)
        ? widget.customerName!.trim()
        : 'العميل';
    final paymentText = ExtensionRequestActionSheet.paymentMethodLabel(
      widget.paymentMethod,
    );

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
          if (!_isSubmitting || _pendingDecision == null) return false;
          final oldStatus = _pendingDecision == _ExtensionDecision.accept
              ? previous.acceptExtensionUsecaseStatus
              : previous.rejectExtensionUsecaseStatus;
          final newStatus = _pendingDecision == _ExtensionDecision.accept
              ? current.acceptExtensionUsecaseStatus
              : current.rejectExtensionUsecaseStatus;
          if (newStatus == BlocStatus.loading) {
            _pendingDecisionStarted = true;
            return false;
          }
          return _pendingDecisionStarted &&
              oldStatus != newStatus &&
              (newStatus == BlocStatus.success ||
                  newStatus == BlocStatus.failed);
        },
        buildWhen: (previous, current) =>
            previous.extensionRequestsUsecas !=
                current.extensionRequestsUsecas ||
            previous.acceptExtensionUsecaseStatus !=
                current.acceptExtensionUsecaseStatus ||
            previous.rejectExtensionUsecaseStatus !=
                current.rejectExtensionUsecaseStatus,
        listener: (context, state) {
          final decisionStatus = _pendingDecision == _ExtensionDecision.accept
              ? state.acceptExtensionUsecaseStatus
              : state.rejectExtensionUsecaseStatus;
          if (decisionStatus == BlocStatus.success) {
            _refreshBookingAfterDecision();
            Navigator.of(context).pop(true);
            return;
          }

          if (decisionStatus == BlocStatus.failed) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
                _pendingDecision = null;
                _pendingDecisionStarted = false;
                _rejectError = ErrorMessageFormatter.format(
                  state.errorMessage,
                  fallback:
                      'تعذر تنفيذ قرار التمديد. حدّث الطلب وحاول مرة أخرى.',
                );
              });
            }
          }
        },
        builder: (context, state) {
          final verified = _trustedWarning(state);
          final minutes =
              verified?.resolvedAdditionalMinutes ?? widget.requestedMinutes;
          final baseAmount = verified?.baseAmount ?? widget.baseAmount;
          final adminMargin = verified?.adminMargin ?? widget.adminMargin;
          final totalAmount =
              verified?.authoritativeQuoteAmount ??
              widget.totalAmount ??
              widget.additionalAmount;
          final currency = verified?.currency ?? widget.currency;
          final currencyText = currency?.trim().isNotEmpty == true
              ? currency!.trim()
              : 'العملة غير محددة';
          final durationText = formatExtensionDurationAr(minutes);
          final isLoading =
              _isSubmitting ||
              state.acceptExtensionUsecaseStatus == BlocStatus.loading ||
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
                            'راجع المبلغ والمدة قبل تأكيد قرارك',
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
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xffEA580C),
                        size: 20,
                      ),
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
                        'تفاصيل مبلغ التمديد',
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xffE5E7EB)),
                      const SizedBox(height: 10),
                      ExtensionRequestAmountBreakdown(
                        baseAmount: baseAmount,
                        adminMargin: adminMargin,
                        totalAmount: totalAmount,
                        currency: currencyText,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                            const Icon(
                              Icons.payments_outlined,
                              color: Color(0xff22C55E),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_rejectError != null) ...[
                  AppText.bodySmall(
                    _rejectError!,
                    color: context.error,
                    textAlign: TextAlign.center,
                  ),
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
                            side: const BorderSide(
                              color: WorkerAppColors.danger,
                            ),
                            foregroundColor: WorkerAppColors.danger,
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isLoading &&
                                  _isSubmitting &&
                                  state.rejectExtensionUsecaseStatus ==
                                      BlocStatus.loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : AppText.labelLarge(
                                  'رفض الطلب',
                                  color: WorkerAppColors.danger,
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: WorkerAppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading || widget.warningId <= 0
                              ? null
                              : _onAccept,
                          child:
                              isLoading &&
                                  state.acceptExtensionUsecaseStatus ==
                                      BlocStatus.loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : AppText.labelLarge(
                                  'قبول الطلب',
                                  color: Colors.white,
                                ),
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

enum _ExtensionDecision { accept, reject }

class ExtensionRequestAmountBreakdown extends StatelessWidget {
  const ExtensionRequestAmountBreakdown({
    required this.baseAmount,
    required this.adminMargin,
    required this.totalAmount,
    required this.currency,
    super.key,
  });

  final double? baseAmount;
  final double? adminMargin;
  final double? totalAmount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (totalAmount != null && totalAmount!.isFinite && totalAmount! >= 0)
        _ExtensionAmountRow(
          key: const Key('extension_total_quote'),
          label: 'المبلغ الإضافي المعتمد',
          amount: totalAmount!,
          currency: currency,
        ),
      if (baseAmount != null && baseAmount!.isFinite && baseAmount! >= 0)
        _ExtensionAmountRow(
          key: const Key('extension_base_amount'),
          label: 'القيمة الأساسية',
          amount: baseAmount!,
          currency: currency,
        ),
    ];

    if (rows.isEmpty) {
      return AppText.bodySmall(
        'المبلغ غير متاح',
        color: const Color(0xff6B7280),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          rows[index],
        ],
      ],
    );
  }
}

class _ExtensionAmountRow extends StatelessWidget {
  const _ExtensionAmountRow({
    required this.label,
    required this.amount,
    required this.currency,
    super.key,
  });

  final String label;
  final double amount;
  final String currency;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: AppText.bodyLarge(
            '${amount.toStringAsFixed(2)} $currency',
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: AppText.bodyLarge(
            label,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
