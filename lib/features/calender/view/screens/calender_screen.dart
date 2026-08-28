import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/theme/app_layout.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_section_header.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_state_view.dart';
import 'package:dllni_cleaninig_owner_app/features/calender/view/manager/calender_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../../orders/view/manager/bloc/orders_bloc.dart';
import '../widgets/calender_app_bar.dart';
import '../widgets/calender_order_card.dart';
import '../widgets/week_calender.dart';

class CalenderScreen extends StatelessWidget {
  CalenderScreen({super.key});

  final CalenderNotifier calenderNotifier = CalenderNotifier();

  FetchOrdersUsecaseParams _params(String? scheduledDate, {int page = 1}) {
    return FetchOrdersUsecaseParams(
      page: page,
      assignedToCurrentWorker: true,
      acceptedByCurrentWorkerOnly: true,
      scheduledDate: scheduledDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd', 'en').format(DateTime.now());
    return BlocProvider<OrdersBloc>(
      create: (_) =>
          getIt<OrdersBloc>()
            ..add(FetchOrdersUsecaseEvent(params: _params(today))),
      child: SafeArea(
        child: Column(
          children: [
            const CalenderAppBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: AppSpace.pagePadding(
                      context,
                    ).add(const EdgeInsetsDirectional.only(top: AppSpace.md)),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsetsDirectional.all(AppSpace.md),
                        decoration: const BoxDecoration(
                          gradient: AppGradients.hero,
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.xl),
                          ),
                          boxShadow: AppShadows.floating,
                        ),
                        child: WeekCalendar(calenderNotifier: calenderNotifier),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: AppSpace.pagePadding(context).add(
                      const EdgeInsetsDirectional.fromSTEB(
                        0,
                        AppSpace.lg,
                        0,
                        AppSpace.sm,
                      ),
                    ),
                    sliver: SliverToBoxAdapter(
                      child: ValueListenableBuilder<String>(
                        valueListenable: calenderNotifier.selectedDate,
                        builder: (context, date, _) => AppSectionHeader(
                          title: 'مهام اليوم',
                          trailing: Text(
                            date,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  BlocBuilder<OrdersBloc, OrdersState>(
                    buildWhen: (previous, current) =>
                        previous.ordersUsecase != current.ordersUsecase,
                    builder: (context, state) {
                      final orders = state.ordersUsecase;
                      void retry() {
                        final lastFilter = context
                            .read<OrdersBloc>()
                            .lastAppliedOrdersListFilter;
                        context.read<OrdersBloc>().add(
                          FetchOrdersUsecaseEvent(
                            params: _params(lastFilter.scheduledDate),
                            isReload: true,
                          ),
                        );
                      }

                      if (orders == null) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppStateView.loading(),
                        );
                      }

                      return orders.builder(
                        loadingWidget: const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppStateView.loading(),
                        ),
                        emptyWidget: const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppStateView.empty(
                            message: 'لا توجد مهام في هذا اليوم',
                          ),
                        ),
                        failedWidget: SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppStateView.error(
                            message: 'تعذّر تحميل مهام هذا اليوم. حاول مجددًا.',
                            onRetry: retry,
                          ),
                        ),
                        successWidget: () => SliverPadding(
                          padding: AppSpace.pagePadding(context).add(
                            const EdgeInsetsDirectional.only(
                              bottom: AppSpace.lg,
                            ),
                          ),
                          sliver: SliverList.separated(
                            itemCount: orders.listLength(1),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpace.sm),
                            itemBuilder: (context, index) {
                              if (orders.length <= index) {
                                if (orders.length == index) {
                                  final lastFilter = context
                                      .read<OrdersBloc>()
                                      .lastAppliedOrdersListFilter;
                                  context.read<OrdersBloc>().add(
                                    FetchOrdersUsecaseEvent(
                                      isReload: false,
                                      params: _params(
                                        lastFilter.scheduledDate,
                                        page: orders.pageNumber,
                                      ),
                                    ),
                                  );
                                }
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.all(
                                      AppSpace.md,
                                    ),
                                    child: CircularProgressIndicator.adaptive(),
                                  ),
                                );
                              }
                              return CalenderOrderCard(
                                date: orders.list[index],
                                index: index,
                              );
                            },
                          ),
                        ),
                        onTapRetry: retry,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
