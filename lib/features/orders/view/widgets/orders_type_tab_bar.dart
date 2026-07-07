import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/order_notifier.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/orders_status_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';

import '../../domain/usecases/fetch_orders_usecase_use_case.dart';

class OrdersTypeTabBar extends StatefulWidget {
  const OrdersTypeTabBar({super.key, required this.orderNotifier});

  final OrderNotifier orderNotifier;

  @override
  State<OrdersTypeTabBar> createState() => _OrdersTypeTabBarState();
}

class _OrdersTypeTabBarState extends State<OrdersTypeTabBar>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ordersStatusTabs.indexWhere(
      (tab) => tab.status == widget.orderNotifier.status.value,
    );
    _tabController = TabController(
      length: ordersStatusTabs.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
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
    return TabBar(
      isScrollable: true,
      onTap: _onTabSelected,
      dividerHeight: .1,
      tabAlignment: TabAlignment.start,
      indicatorColor: context.primary,
      controller: _tabController,
      tabs: ordersStatusTabs
          .map((tab) => Tab(child: AppText.labelLarge(tab.label)))
          .toList(growable: false),
      labelPadding: const EdgeInsetsDirectional.symmetric(
        vertical: 3,
        horizontal: 10,
      ),
      labelColor: Colors.black,
      indicator: MaterialIndicator(
        height: 2,
        topLeftRadius: 8,
        topRightRadius: 8,
        bottomLeftRadius: 8,
        bottomRightRadius: 8,
        tabPosition: TabPosition.bottom,
        color: context.primary,
      ),
    );
  }
}
