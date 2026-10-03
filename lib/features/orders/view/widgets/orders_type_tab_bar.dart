import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/order_notifier.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/orders_status_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/worker_app_colors.dart';
import '../../domain/usecases/fetch_orders_usecase_use_case.dart';

class OrdersTypeTabBar extends StatefulWidget {
  const OrdersTypeTabBar({super.key, required this.orderNotifier});

  final OrderNotifier orderNotifier;

  @override
  State<OrdersTypeTabBar> createState() => _OrdersTypeTabBarState();
}

class _OrdersTypeTabBarState extends State<OrdersTypeTabBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final initial = ordersStatusTabs.indexWhere(
      (tab) => tab.status == widget.orderNotifier.status.value,
    );
    _selectedIndex = initial >= 0 ? initial : 0;
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
    final tab = ordersStatusTabs[index];
    widget.orderNotifier.changeStatus(tab.status);
    context.read<OrdersBloc>().add(
      FetchOrdersUsecaseEvent(
        params: FetchOrdersUsecaseParams(
          page: 1,
          status: tab.status,
          assignedToCurrentWorker: true,
        ),
        isReload: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: ordersStatusTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = ordersStatusTabs[index];
          final selected = _selectedIndex == index;
          return Material(
            color: selected
                ? WorkerAppColors.brandPrimary
                : WorkerAppColors.surface,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? WorkerAppColors.brandPrimary
                    : WorkerAppColors.border,
              ),
            ),
            child: InkWell(
              onTap: () => _onTabSelected(index),
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),
                child: Text(
                  tab.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? Colors.white
                        : WorkerAppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
