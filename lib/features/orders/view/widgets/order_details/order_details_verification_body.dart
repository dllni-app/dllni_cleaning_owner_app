import 'package:common_package/common_package.dart';
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
  @override
  void initState() {
    super.initState();
    final id = widget.order.id;
    if (id != null) {
      widget.bloc.add(FetchSecurityCodeEvent(params: FetchSecurityCodeParams(id: id)));
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
                    if (id != null)
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
