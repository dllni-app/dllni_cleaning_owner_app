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
  }) async {
    final reasonController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return BlocProvider.value(
          value: bloc,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
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
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppText.titleMedium(
                              'طلب تمديد مدة العمل',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppText.bodyMedium(
                        'أحمد أحمد يطلب تمديد الخدمة ${requestedMinutes ?? 0} دقيقة',
                        color: context.primaryContainer,
                      ),
                      if (bookingId != null) ...[
                        const SizedBox(height: 6),
                        AppText.bodySmall(
                          'حجز #$bookingId',
                          color: context.colorScheme.outline,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xffF8FAFC),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bodySmall(
                              'مرابحك الإضافية',
                              color: context.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText.bodyMedium(
                                  'الإجمالي',
                                  fontWeight: FontWeight.bold,
                                ),
                                AppText.titleSmall(
                                  'ل.س 80.00',
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AppText.bodySmall(
                              'نقداً عند الاستلام',
                              color: context.colorScheme.outline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'كتابة رسالة اعتذار',
                          hintText: 'اكتب رسالة توضيحية للعميل...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
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
                                color: context.onPrimary,
                              ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // Current API accepts only warning id for rejection.
                                // Reason text remains UI-only until endpoint supports it.
                                bloc.add(
                                  RejectExtensionUsecaseEvent(
                                    params: RejectExtensionUsecaseParams(
                                      id: warningId,
                                    ),
                                  ),
                                );
                              },
                        child: AppText.labelLarge(
                          'كتابة رسالة اعتذار',
                          color: context.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    reasonController.dispose();
  }
}
