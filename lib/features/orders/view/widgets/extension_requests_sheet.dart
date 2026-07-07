import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_extension_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_extension_requests_usecas_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_extension_usecase_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../manager/bloc/orders_bloc.dart';

class ExtensionRequestsSheet {
  static Future<void> show(
    BuildContext context, {
    OrdersBloc? bloc,
    VoidCallback? onChanged,
  }) async {
    final ordersBloc = bloc ?? context.read<OrdersBloc>();
    ordersBloc.add(
      FetchExtensionRequestsUsecasEvent(
        params: FetchExtensionRequestsUsecasParams(),
        isReload: true,
      ),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return BlocProvider.value(
                value: ordersBloc,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    12.verticalSpace,
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    16.verticalSpace,
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 20.w,
                      ),
                      child: AppText.titleMedium(
                        'طلبات تمديد الوقت',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    12.verticalSpace,
                    Expanded(
                      child: BlocConsumer<OrdersBloc, OrdersState>(
                        bloc: ordersBloc,
                        listenWhen: (previous, current) {
                          final acceptedNow = previous.acceptExtensionUsecaseStatus != BlocStatus.success &&
                              current.acceptExtensionUsecaseStatus == BlocStatus.success;
                          final rejectedNow = previous.rejectExtensionUsecaseStatus != BlocStatus.success &&
                              current.rejectExtensionUsecaseStatus == BlocStatus.success;
                          return acceptedNow || rejectedNow;
                        },
                        buildWhen: (previous, current) =>
                            previous.extensionRequestsUsecas != current.extensionRequestsUsecas ||
                            previous.acceptExtensionUsecaseStatus != current.acceptExtensionUsecaseStatus ||
                            previous.rejectExtensionUsecaseStatus != current.rejectExtensionUsecaseStatus ||
                            previous.errorMessage != current.errorMessage,
                        listener: (context, state) {
                          onChanged?.call();
                        },
                        builder: (context, state) {
                          return state.extensionRequestsUsecas!.builder(
                            loadingWidget: Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                            emptyWidget: Center(
                              child: AppText.bodyMedium('لا توجد طلبات'),
                            ),
                            successWidget: () {
                              final list = state.extensionRequestsUsecas!.list;
                              return ListView.builder(
                                controller: scrollController,
                                padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  final wid = item.id;
                                  return Card(
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.all(12.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText.bodyMedium(
                                            'حجز #${item.bookingId} — ${item.requestedMinutes} دقيقة',
                                          ),
                                          12.verticalSpace,
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed:
                                                      wid == null ||
                                                          state.rejectExtensionUsecaseStatus ==
                                                              BlocStatus.loading
                                                      ? null
                                                      : () {
                                                          ordersBloc.add(
                                                            RejectExtensionUsecaseEvent(
                                                              params:
                                                                  RejectExtensionUsecaseParams(
                                                                    id: wid,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                  child: AppText.labelLarge(
                                                    'رفض',
                                                    color: context.error,
                                                  ),
                                                ),
                                              ),
                                              12.horizontalSpace,
                                              Expanded(
                                                child: FilledButton(
                                                  onPressed:
                                                      wid == null ||
                                                          state.acceptExtensionUsecaseStatus ==
                                                              BlocStatus.loading
                                                      ? null
                                                      : () {
                                                          ordersBloc.add(
                                                            AcceptExtensionUsecaseEvent(
                                                              params:
                                                                  AcceptExtensionUsecaseParams(
                                                                    id: wid,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                  child: AppText.labelLarge(
                                                    'قبول',
                                                    color: context.onPrimary,
                                                  ),
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
                            },
                            failedWidget: AppText.bodyMedium(
                              ErrorMessageFormatter.format(
                                state.errorMessage,
                                fallback: 'خطأ',
                              ),
                              color: context.error,
                            ),
                            onTapRetry: () {
                              ordersBloc.add(
                                FetchExtensionRequestsUsecasEvent(
                                  params: FetchExtensionRequestsUsecasParams(),
                                  isReload: true,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
