import 'package:dllni_cleaninig_owner_app/core/theme/app_layout.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/order_notifier.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/orders_status_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/fetch_orders_usecase_use_case.dart';

class OrdersTypeTabBar extends StatelessWidget {
  const OrdersTypeTabBar({super.key, required this.orderNotifier});

  final OrderNotifier orderNotifier;

  void _select(BuildContext context, String status) {
    if (orderNotifier.status.value == status) return;
    orderNotifier.changeStatus(status);
    context.read<OrdersBloc>().add(
      FetchOrdersUsecaseEvent(
        params: FetchOrdersUsecaseParams(
          page: 1,
          status: status,
          assignedToCurrentWorker: true,
        ),
        isReload: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: ValueListenableBuilder<String>(
        valueListenable: orderNotifier.status,
        builder: (context, selectedStatus, _) => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: ordersStatusTabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
          itemBuilder: (context, index) {
            final tab = ordersStatusTabs[index];
            final selected = tab.status == selectedStatus;
            return Semantics(
              button: true,
              selected: selected,
              label: tab.label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _select(context, tab.status),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: AppMotion.resolved(context, AppMotion.standard),
                    alignment: Alignment.center,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      tab.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
