import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_security_code_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_work_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../helpers/cleaning_security_code_display.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../order_details_map_app_bar.dart';

class OrderDetailsVerificationBody extends StatefulWidget {
  const OrderDetailsVerificationBody({super.key, required this.order, required this.bloc});

  final FetchOrdersUsecaseModelDataItem order;
  final OrdersBloc bloc;

  @override
  State<OrderDetailsVerificationBody> createState() => _OrderDetailsVerificationBodyState();
}

class _OrderDetailsVerificationBodyState extends State<OrderDetailsVerificationBody> {
  bool _isSubmittingPriceAdjustment = false;

  @override
  void initState() {
    super.initState();
    final id = widget.order.id;
    if (id != null) {
      widget.bloc.add(FetchSecurityCodeEvent(params: FetchSecurityCodeParams(id: id)));
    }
  }

  Future<void> _openPriceAdjustmentSheet() async {
    final id = widget.order.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد رقم الطلب')),
      );
      return;
    }

    final priceController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText.titleMedium(
                  'طلب تعديل السعر',
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                12.verticalSpace,
                AppText.bodyMedium(
                  'أدخل السعر الجديد المقترح وسيتم إرساله للإدارة للمراجعة.',
                  textAlign: TextAlign.center,
                  color: Theme.of(sheetContext).colorScheme.outline,
                ),
                20.verticalSpace,
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'أدخل السعر الجديد المقترح',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'يرجى إدخال سعر صحيح أكبر من صفر';
                    }
                    return null;
                  },
                ),
                12.verticalSpace,
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'سبب التعديل - اختياري',
                    border: OutlineInputBorder(),
                  ),
                ),
                16.verticalSpace,
                ElevatedButton(
                  onPressed: _isSubmittingPriceAdjustment
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          await _submitPriceAdjustmentRequest(
                            id: id,
                            price: double.parse(priceController.text.trim()),
                            reason: reasonController.text.trim(),
                          );
                          if (sheetContext.mounted && mounted && !_isSubmittingPriceAdjustment) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                  child: _isSubmittingPriceAdjustment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال للإدارة'),
                ),
              ],
            ),
          ),
        );
      },
    );

    priceController.dispose();
    reasonController.dispose();
  }

  Future<void> _submitPriceAdjustmentRequest({
    required int id,
    required double price,
    required String reason,
  }) async {
    setState(() => _isSubmittingPriceAdjustment = true);
    try {
      await getIt<DioNetwork>().postData(
        endPoint: '/api/v1/cleaning-bookings/$id/price-adjustment-requests',
        data: <String, dynamic>{
          'proposedTotalPrice': price,
          if (reason.isNotEmpty) 'reason': reason,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب التعديل للإدارة، يرجى الانتظار لحين التواصل')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال طلب تعديل السعر حالياً')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingPriceAdjustment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.order.id;
    return Column(
      children: [
        OrderDetailsMapAppBar(orderNum: widget.order.bookingNumber ?? ''),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: 24.w),
            child: BlocBuilder<OrdersBloc, OrdersState>(
              bloc: widget.bloc,
              builder: (context, state) {
                if (state.securityCodeStatus == BlocStatus.loading) {
                  return Center(child: CircularProgressIndicator.adaptive());
                }
                if (state.securityCodeStatus == BlocStatus.failed) {
                  return Center(child: AppText.bodyMedium(state.errorMessage ?? 'تعذر تحميل الرمز', color: context.error));
                }
                final code = state.securityCode?.data?.securityCode ?? '----';
                final expires = state.securityCode?.data?.expiresAt;
                final formattedExpiry = formatCleaningSecurityCodeDateTime(expires);
                final bookingLabel = formatCleaningBookingLabel(
                  bookingId: widget.order.id,
                  bookingNumber: widget.order.bookingNumber,
                );
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText.titleMedium('رمز التحقق للعميل', fontWeight: FontWeight.bold, textAlign: TextAlign.center),
                    12.verticalSpace,
                    AppText.labelMedium(
                      'رقم الحجز: $bookingLabel',
                      textAlign: TextAlign.center,
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    if (formattedExpiry.isNotEmpty) ...[
                      8.verticalSpace,
                      AppText.labelMedium(
                        'صالح حتى: $formattedExpiry',
                        textAlign: TextAlign.center,
                        color: context.colorScheme.outline,
                      ),
                    ],
                    24.verticalSpace,
                    Container(
                      padding: EdgeInsetsDirectional.symmetric(vertical: 20.h, horizontal: 32.w),
                      decoration: BoxDecoration(
                        color: context.primaryContainer.withAlpha(40),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.primary),
                      ),
                      child: AppText.displaySmall(code, fontWeight: FontWeight.bold),
                    ),
                    32.verticalSpace,
                    AppText.bodyMedium(
                      'اطلب من العميل إدخال هذا الرمز في تطبيقه لتأكيد وصولك قبل بدء العمل.',
                      textAlign: TextAlign.center,
                      color: context.colorScheme.outline,
                    ),
                    24.verticalSpace,
                    if (id != null) ...[
                      InkWell(
                        onTap: _isSubmittingPriceAdjustment ? null : _openPriceAdjustmentSheet,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.primary),
                            color: Colors.white,
                          ),
                          padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                          child: AppText.labelLarge(
                            'طلب تعديل السعر',
                            color: context.primary,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      12.verticalSpace,
                      InkWell(
                        onTap: state.startWorkStatus == BlocStatus.loading
                            ? null
                            : () {
                                widget.bloc.add(StartWorkEvent(params: StartWorkParams(id: id)));
                              },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primary),
                          padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                          child: state.startWorkStatus == BlocStatus.loading
                              ? Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: context.onPrimary, strokeWidth: 2),
                                  ),
                                )
                              : AppText.labelLarge('بدء العمل', color: context.onPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
