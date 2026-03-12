import 'package:common_package/widgets/app_text.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/completed_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/order_card.dart';
import '../../domain/usecases/fetch_orders_usecase_use_case.dart';
import '../manager/bloc/orders_bloc.dart';
import '../manager/order_notifier.dart';
import '../widgets/order_warning_card.dart';
import '../widgets/orders_app_bar.dart';
import '../widgets/orders_type_tab_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderNotifier orderNotifier = OrderNotifier();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersBloc>(
      lazy: false,
      create: (context) =>
          getIt<OrdersBloc>()..add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'pending'), isReload: true)),
      child: SafeArea(
        child: Column(
          children: [
            OrdersAppBar(),
            // SizedBox(height: 20),
            // OrderWarningCard(),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: OrdersTypeTabBar(orderNotifier: orderNotifier),
            ),
            SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<OrdersBloc, OrdersState>(
                buildWhen: (previous, current) => previous.ordersUsecase != current.ordersUsecase,
                builder: (context, state) {
                  return state.ordersUsecase!.builder(
                    loadingWidget: Padding(
                      padding: EdgeInsetsDirectional.only(top: 40),
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    ),
                    emptyWidget: AppText.labelMedium('لا يوجد مهام', fontWeight: FontWeight.w400),
                    successWidget: () {
                      return ValueListenableBuilder(
                        valueListenable: orderNotifier.status,
                        builder: (context, status, _) => ListView.separated(
                          padding: EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 20),
                          itemBuilder: (context, index) {
                            if (state.ordersUsecase!.length <= index) {
                              if (state.ordersUsecase!.length == index) {
                                context.read<OrdersBloc>().add(
                                  FetchOrdersUsecaseEvent(
                                    isReload: false,
                                    params: FetchOrdersUsecaseParams(page: state.ordersUsecase!.pageNumber, status: status),
                                  ),
                                );
                              }
                              return SizedBox(width: 30, height: 30, child: FittedBox(child: CircularProgressIndicator.adaptive(strokeWidth: 3)));
                            }
                            return status != 'completed'
                                ? OrderCard(
                                    date: state.ordersUsecase!.list[index],
                                    orderStatus: state.ordersUsecase!.list[index].status == 'worker_assigned'
                                        ? OrderStatus.workerAssigned
                                        : state.ordersUsecase!.list[index].status == 'in_progress'
                                        ? OrderStatus.inProgress
                                        : OrderStatus.pending,
                                    bloc: context.read<OrdersBloc>(),
                                    index: index,
                                  )
                                : CompletedOrderCard(date: state.ordersUsecase!.list[index]);
                          },
                          separatorBuilder: (context, index) => SizedBox(height: 16),
                          itemCount: state.ordersUsecase!.listLength(1),
                        ),
                      );
                    },
                    onTapRetry: () {
                      context.read<OrdersBloc>().add(
                        FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'worker_assigned'), isReload: true),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
