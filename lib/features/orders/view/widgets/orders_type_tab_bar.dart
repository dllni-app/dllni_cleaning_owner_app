import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/order_notifier.dart';
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

class _OrdersTypeTabBarState extends State<OrdersTypeTabBar> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: false,
      onTap: (i) {
        if (i == 0) {
          context.read<OrdersBloc>().add(
            FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'worker_assigned'), isReload: true),
          );
        }
        if (i == 1) {
          context.read<OrdersBloc>().add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'in_progress'), isReload: true));
        }
        if (i == 2) {
          context.read<OrdersBloc>().add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'completed'), isReload: true));
        }
        widget.orderNotifier.status.value = i == 0
            ? 'worker_assigned'
            : i == 1
            ? 'in_progress'
            : 'completed';
      },
      dividerHeight: .1,
      tabAlignment: TabAlignment.center,
      indicatorColor: context.primary,
      controller: _tabController,
      labelPadding: EdgeInsetsDirectional.symmetric(vertical: 3, horizontal: 10),
      tabs: [AppText.labelLarge('الطلبات الجديدة'), AppText.labelLarge('الطلبات المؤكدة'), AppText.labelLarge('الطلبات المكتملة')],
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
