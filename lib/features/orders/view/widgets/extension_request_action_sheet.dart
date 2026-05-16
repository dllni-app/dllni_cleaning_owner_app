import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExtensionRequestActionSheet {
  static Future<void> show(
    BuildContext context, {
    required OrdersBloc bloc,
    required int warningId,
    int? bookingId,
    int? requestedMinutes,
    String? customerName,
    double? additionalAmount,
    String? currency,
    String? paymentMethod,
  }) async {
    final messageController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: bloc,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            ),
            child: BlocConsumer<OrdersBloc, OrdersState>(
              bloc: bloc,
              listener: (context, state) {
                if (state.acceptExtensionUsecaseStatus == BlocStatus.success ||
                    state.rejectExtensionUsecaseStatus == BlocStatus.success) {
                  Navigator.of(ctx).pop();
                }
              },
              builder: (context, state) {
                final isLoading =
                    state.acceptExtensionUsecaseStatus == BlocStatus.loading ||
                    state.rejectExtensionUsecaseStatus == BlocStatus.loading;
                final amountText = additionalAmount == null
                    ? '-'
                    : additionalAmount.toStringAsFixed(2);
                final currencyText = (currency?.trim().isNotEmpty ?? false)
                    ? currency!.trim()
                    : 'ل.س';
                final customerText = (customerName?.trim().isNotEmpty ?? false)
                    ? customerName!.trim()
                    : 'العميل';
                final paymentText = _paymentMethodLabel(paymentMethod);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                        Expanded(
                          child: AppText.titleMedium(
                            'طلب تمديد مدة العمل',
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF7ED),
                        border: Border.all(color: const Color(0xffFDBA74)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xffC2410C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppText.bodyMedium(
                              '$customerText يطلب تمديد مدة الخدمة ${requestedMinutes ?? 0} دقيقة إضافية',
                              color: const Color(0xff9A3412),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            'مربحك الإضافية',
                            color: const Color(0xff6B7280),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.bodyLarge(
                                'الإجمالي',
                                fontWeight: FontWeight.w700,
                              ),
                              AppText.bodyLarge(
                                '$amountText $currencyText',
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: Color(0xff22C55E),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: AppText.bodySmall(
                                  paymentText,
                                  color: const Color(0xff374151),
                                ),
                              ),
                            ],
                          ),
                          if (bookingId != null) ...[
                            const SizedBox(height: 6),
                            AppText.bodySmall(
                              'حجز #$bookingId',
                              color: const Color(0xff9CA3AF),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLength: 150,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'كتابة رسالة اعتذار',
                        hintText: 'اكتب رسالة توضيحية للعميل...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    bloc.add(
                                      RejectExtensionUsecaseEvent(
                                        params: RejectExtensionUsecaseParams(
                                          id: warningId,
                                          message: messageController.text,
                                        ),
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xffEF4444)),
                              foregroundColor: const Color(0xffEF4444),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: AppText.labelLarge(
                              'كتابة رسالة اعتذار',
                              color: const Color(0xffEF4444),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    bloc.add(
                                      AcceptExtensionUsecaseEvent(
                                        params: AcceptExtensionUsecaseParams(
                                          id: warningId,
                                        ),
                                      ),
                                    );
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff1DBCC8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : AppText.labelLarge(
                                    'الموافقة على طلب التمديد',
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    messageController.dispose();
  }

  static String _paymentMethodLabel(String? paymentMethod) {
    final value = (paymentMethod ?? '').trim().toLowerCase();
    if (value == 'cash' || value == 'cash_on_delivery') {
      return 'نقدا عند الاستلام';
    }
    if (value == 'card') {
      return 'دفع إلكتروني';
    }
    if (value.isEmpty) {
      return 'طريقة الدفع غير محددة';
    }
    return paymentMethod!;
  }
}
