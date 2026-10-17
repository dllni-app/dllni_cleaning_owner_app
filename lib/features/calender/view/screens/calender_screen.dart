import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/theme/worker_app_colors.dart';
import 'package:dllni_cleaninig_owner_app/features/calender/view/manager/calender_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../../orders/view/manager/bloc/orders_bloc.dart';
import '../widgets/calender_app_bar.dart';
import '../widgets/calender_order_card.dart';
import '../widgets/week_calender.dart';

/// Worker-first agenda. Keep booking data and pagination sourced from OrdersBloc.
class CalenderScreen extends StatefulWidget {
  const CalenderScreen({super.key});

  @override
  State<CalenderScreen> createState() => _CalenderScreenState();
}

class _CalenderScreenState extends State<CalenderScreen> {
  late final OrdersBloc _ordersBloc;
  final CalenderNotifier calenderNotifier = CalenderNotifier();

  @override
  void initState() {
    super.initState();
    _ordersBloc = getIt<OrdersBloc>();
    _fetchSelectedDay();
  }

  void _fetchSelectedDay() {
    final filter = _ordersBloc.lastAppliedOrdersListFilter;
    final selectedDate = filter.scheduledDate;
    _ordersBloc.add(
      FetchOrdersUsecaseEvent(
        params: FetchOrdersUsecaseParams(
          page: 1,
          assignedToCurrentWorker: true,
          acceptedByCurrentWorkerOnly: true,
          scheduledDate: selectedDate == null || selectedDate.isEmpty
              ? DateFormat('yyyy-MM-dd', 'en').format(DateTime.now())
              : selectedDate,
        ),
        isReload: true,
      ),
    );
  }

  @override
  void dispose() {
    calenderNotifier.selectedDate.dispose();
    _ordersBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersBloc>.value(
      value: _ordersBloc,
      child: SafeArea(
        child: ColoredBox(
          color: WorkerAppColors.canvas,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CalenderAppBar(),
              Container(
                margin: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: WorkerAppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WorkerAppColors.border),
                ),
                child: WeekCalendar(calenderNotifier: calenderNotifier),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      color: WorkerAppColors.brandPrimary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: calenderNotifier.selectedDate,
                        builder: (_, date, __) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'جدول المهام',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: WorkerAppColors.textPrimary,
                              ),
                            ),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: WorkerAppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'تحديث المهام',
                      onPressed: _fetchSelectedDay,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: WorkerAppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<OrdersBloc, OrdersState>(
                  buildWhen: (a, b) => a.ordersUsecase != b.ordersUsecase,
                  builder: (context, state) {
                    final orders = state.ordersUsecase;
                    if (orders == null) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }
                    return orders.builder(
                      loadingWidget: const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      emptyWidget: _MessageState(
                        icon: Icons.event_available_outlined,
                        title: 'يومك خالٍ من المهام',
                        detail:
                            'لا توجد مهام مسندة إليك في هذا اليوم. اختر يوماً آخر.',
                        onRetry: _fetchSelectedDay,
                      ),
                      failedWidget: _MessageState(
                        icon: Icons.wifi_off_rounded,
                        title: 'تعذر تحميل الجدول',
                        detail: 'تحقق من الاتصال ثم حاول مجدداً.',
                        onRetry: _fetchSelectedDay,
                      ),
                      successWidget: () => RefreshIndicator(
                        onRefresh: () async => _fetchSelectedDay(),
                        child: ListView.separated(
                          key: ValueKey(
                            _ordersBloc
                                .lastAppliedOrdersListFilter
                                .scheduledDate,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            8,
                            16,
                            28,
                          ),
                          itemCount: orders.listLength(1),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= orders.length) {
                              if (index == orders.length) {
                                final last =
                                    _ordersBloc.lastAppliedOrdersListFilter;
                                _ordersBloc.add(
                                  FetchOrdersUsecaseEvent(
                                    params: FetchOrdersUsecaseParams(
                                      page: orders.pageNumber,
                                      assignedToCurrentWorker: true,
                                      acceptedByCurrentWorkerOnly: true,
                                      scheduledDate: last.scheduledDate,
                                    ),
                                    isReload: false,
                                  ),
                                );
                              }
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              );
                            }
                            return CalenderOrderCard(
                              key: ValueKey(orders.list[index].id),
                              date: orders.list[index],
                              index: index,
                            );
                          },
                        ),
                      ),
                      onTapRetry: _fetchSelectedDay,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: WorkerAppColors.brandPrimary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WorkerAppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }
}
