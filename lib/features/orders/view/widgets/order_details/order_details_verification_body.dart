import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/repository/orders_repo.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_security_code_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/request_booking_price_adjustment_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_work_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _priceAdjustmentLoading = false;
  bool _priceAdjustmentSent = false;

  @override
  void initState() {
    super.initState();
    final id = widget.order.id;
    if (id != null) {
      widget.bloc.add(FetchSecurityCodeEvent(params: FetchSecurityCodeParams(id: id)));
    }
  }

  bool get _isHotOrder {
    final raw = widget.order.scheduledDate?.trim();
    if (raw == null || raw.isEmpty) return false;
    final scheduled = DateTime.tryParse(raw);
    if (scheduled == null) return false;
    final now = DateTime.now();
    return scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;
  }

  String get _currentPriceText {
    final price = widget.order.totalPrice;
    if (price == null || price <= 0) return '';
    final rounded = price.round();
    return rounded.toString();
  }

  Future<void> _openPriceAdjustmentSheet() async {
    final id = widget.order.id;
    if (id == null || _priceAdjustmentLoading || _priceAdjustmentSent) return;

    final priceController = TextEditingController(text: _currentPriceText);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final draft = await showModalBottomSheet<_PriceAdjustmentDraft>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                const SizedBox(height: 8),
                AppText.bodyMedium(
                  'استخدم هذا الطلب عندما لا يغطي السعر الحالي حجم العمل المطلوب. سيتم إرساله للإدارة للمراجعة قبل بدء العمل.',
                  color: const Color(0xff6B7280),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'السعر المقترح',
                    hintText: 'مثال: 75000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final normalized = (value ?? '').replaceAll(',', '').trim();
                    final price = double.tryParse(normalized);
                    if (price == null || price <= 0) {
                      return 'يرجى إدخال سعر صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'سبب التعديل',
                    hintText: 'مثال: حجم العمل أكبر من الوصف أو يوجد متطلبات إضافية.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() != true) return;
                          final normalized = priceController.text.replaceAll(',', '').trim();
                          Navigator.of(ctx).pop(
                            _PriceAdjustmentDraft(
                              proposedTotalPrice: double.parse(normalized),
                              reason: reasonController.text.trim(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff1DBCC8),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إرسال الطلب'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    priceController.dispose();
    reasonController.dispose();

    if (draft == null || !mounted) return;
    await _sendPriceAdjustment(id, draft);
  }

  Future<void> _sendPriceAdjustment(
    int bookingId,
    _PriceAdjustmentDraft draft,
  ) async {
    setState(() => _priceAdjustmentLoading = true);
    final response = await getIt<OrdersRepo>().requestBookingPriceAdjustment(
      RequestBookingPriceAdjustmentParams(
        id: bookingId,
        proposedTotalPrice: draft.proposedTotalPrice,
        reason: draft.reason,
      ),
    );
    if (!mounted) return;
    setState(() => _priceAdjustmentLoading = false);

    response.fold(
      (failure) => AppToast.showErrorGlobal(
        ErrorMessageFormatter.format(failure.message),
      ),
      (_) {
        setState(() => _priceAdjustmentSent = true);
        AppToast.showSuccessGlobal(
          'تم إرسال طلب تعديل السعر للإدارة، يرجى الانتظار لحين المراجعة.',
        );
        widget.bloc.add(
          FetchOrderDetailsUsecaseEvent(
            params: FetchOrderDetailsUsecaseParams(id: bookingId),
          ),
        );
      },
    );
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
                  return Center(
                    child: AppText.bodyMedium(
                      ErrorMessageFormatter.format(
                        state.errorMessage,
                        fallback: 'تعذر تحميل الرمز',
                      ),
                      color: context.error,
                    ),
                  );
                }
                final code = state.securityCode?.data?.securityCode ?? '----';
                final expires = state.securityCode?.data?.expiresAt;
                final formattedExpiry = formatCleaningSecurityCodeDateTime(expires);
                final bookingLabel = formatCleaningBookingLabel(
                  bookingId: widget.order.id,
                  bookingNumber: widget.order.bookingNumber,
                );
                return SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isHotOrder) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xffDC2626)),
                              8.horizontalSpace,
                              Expanded(
                                child: AppText.bodyMedium(
                                  '[🚨 طلب ساخن - تنفيذ فوري عاجل]',
                                  color: const Color(0xff991B1B),
                                  fontWeight: FontWeight.bold,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                        18.verticalSpace,
                      ],
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
                        OutlinedButton.icon(
                          onPressed: _priceAdjustmentLoading || _priceAdjustmentSent
                              ? null
                              : _openPriceAdjustmentSheet,
                          icon: _priceAdjustmentLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.primary,
                                  ),
                                )
                              : const Icon(Icons.price_change_outlined),
                          label: Text(
                            _priceAdjustmentSent
                                ? 'تم إرسال طلب تعديل السعر'
                                : 'طلب تعديل السعر',
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            foregroundColor: const Color(0xff1E2A78),
                            side: const BorderSide(color: Color(0xff1E2A78)),
                          ),
                        ),
                        10.verticalSpace,
                        if (_priceAdjustmentSent) ...[
                          AppText.bodySmall(
                            'لا تبدأ العمل حتى تتم مراجعة طلب التعديل من الإدارة.',
                            color: const Color(0xffB45309),
                            textAlign: TextAlign.center,
                          ),
                          10.verticalSpace,
                        ],
                        InkWell(
                          onTap: state.startWorkStatus == BlocStatus.loading || _priceAdjustmentSent
                              ? null
                              : () {
                                  widget.bloc.add(StartWorkEvent(params: StartWorkParams(id: id)));
                                },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: _priceAdjustmentSent ? const Color(0xffCBD5E1) : context.primary,
                            ),
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                            child: state.startWorkStatus == BlocStatus.loading
                                ? Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: context.onPrimary, strokeWidth: 2),
                                    ),
                                  )
                                : AppText.labelLarge(
                                    _priceAdjustmentSent ? 'بانتظار مراجعة السعر' : 'بدء العمل',
                                    color: _priceAdjustmentSent ? const Color(0xff475569) : context.onPrimary,
                                    fontWeight: FontWeight.w500,
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceAdjustmentDraft {
  const _PriceAdjustmentDraft({required this.proposedTotalPrice, this.reason});

  final double proposedTotalPrice;
  final String? reason;
}
