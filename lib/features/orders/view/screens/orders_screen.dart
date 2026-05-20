import 'dart:async';

import 'package:common_package/helpers/pusher_service_logger.dart';
import 'package:common_package/widgets/app_text.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_extension_prompts.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/order_card.dart';
import '../../domain/usecases/fetch_orders_usecase_use_case.dart';
import '../manager/bloc/orders_bloc.dart';
import '../manager/order_notifier.dart';
import '../widgets/orders_app_bar.dart';
import '../widgets/orders_type_tab_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const Duration _fallbackDebounce = Duration(milliseconds: 150);

  final OrderNotifier orderNotifier = OrderNotifier();
  late final OrdersBloc _ordersBloc;
  int? _workerId;
  bool _workerRealtimeAuthWarningShown = false;
  Timer? _fallbackRefreshDebounce;

  int? _resolveWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  @override
  void initState() {
    super.initState();
    final initialStatus = widget.initialStatus;
    final hasInitialStatus = initialStatus != null && initialStatus.trim().isNotEmpty;
    final firstFetchStatus = hasInitialStatus ? initialStatus : CleaningBookingStatus.workerAssigned;
    if (hasInitialStatus) {
      orderNotifier.changeStatus(initialStatus);
    }
    _ordersBloc = getIt<OrdersBloc>()..add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: firstFetchStatus), isReload: true));
    _workerId = _resolveWorkerId();
    if (_workerId != null) {
      final pusher = getIt<CleaningBookingPusherService>();
      pusher.setWorkerHandler(_workerId!, (eventName, payload) {
        if (!mounted) return;
        final normalizedEvent = CleaningRealtimeContract.normalizeEventName(eventName);
        if (normalizedEvent == CleaningRealtimeContract.serviceExtensionRequested ||
            (normalizedEvent == CleaningRealtimeContract.completionDecisionMade && (payload['decision'] ?? '').toString().trim().toLowerCase() == 'extension_requested')) {
          unawaited(CleaningWorkerExtensionPrompts.dispatchRealtimeEvent(eventName, payload));
        }
        if (!CleaningRealtimeContract.isLifecycleRefreshEvent(normalizedEvent)) {
          return;
        }
        unawaited(CleaningWorkerExtensionPrompts.pollPendingExtensions());
        _scheduleFallbackRefresh(reason: 'worker_lifecycle_event_refresh');
      });
      pusher.setWorkerErrorHandler(_workerId!, _onWorkerRealtimeError);
      unawaited(pusher.subscribeWorkerChannel(_workerId!));
    }
  }

  void _onWorkerRealtimeError(RealtimeChannelError error) {
    if (error.statusCode != 403) return;
    _scheduleFallbackRefresh(reason: 'worker_channel_auth_403_refresh');
    if (_workerRealtimeAuthWarningShown || !mounted) return;
    _workerRealtimeAuthWarningShown = true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر استقبال التحديث المباشر حالياً. سيتم تحديث الطلبات تلقائياً في الخلفية.')));
  }

  void _scheduleFallbackRefresh({required String reason}) {
    _fallbackRefreshDebounce?.cancel();
    _fallbackRefreshDebounce = Timer(_fallbackDebounce, () {
      if (!mounted) return;
      PusherServiceLogger.event(
        'private-cleaning-worker.${_workerId ?? ''}',
        'CleaningBookingTrackingUpdated',
        <String, dynamic>{'status': orderNotifier.status.value},
        eventHandledAtMs: DateTime.now().millisecondsSinceEpoch,
        fallbackReason: reason,
      );
      _ordersBloc.add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: orderNotifier.status.value), isReload: true));
    });
  }

  @override
  void dispose() {
    _fallbackRefreshDebounce?.cancel();
    if (_workerId != null) {
      final pusher = getIt<CleaningBookingPusherService>();
      pusher.setWorkerHandler(_workerId!, null);
      pusher.setWorkerErrorHandler(_workerId!, null);
      unawaited(pusher.unsubscribeWorkerChannel(_workerId!));
    }
    _ordersBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersBloc>(
      lazy: false,
      create: (context) => _ordersBloc,
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
                  final orders = state.ordersUsecase;
                  if (orders == null) {
                    return const Padding(
                      padding: EdgeInsetsDirectional.only(top: 40),
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    );
                  }
                  return orders.builder(
                    loadingWidget: Padding(
                      padding: EdgeInsetsDirectional.only(top: 40),
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    ),
                    emptyWidget: AppText.labelMedium('لا يوجد مهام', fontWeight: FontWeight.w400),
                    failedWidget: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 40),
                      child: Center(
                        child: AppText.labelMedium(
                          orders.errorMessage.isNotEmpty ? orders.errorMessage : (state.errorMessage ?? 'تعذر تحميل المهام'),
                          fontWeight: FontWeight.w400,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    successWidget: () {
                      return ValueListenableBuilder(
                        valueListenable: orderNotifier.status,
                        builder: (context, status, _) => ListView.separated(
                          padding: EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 20),
                          itemBuilder: (context, index) {
                            if (orders.length <= index) {
                              if (orders.length == index) {
                                context.read<OrdersBloc>().add(
                                  FetchOrdersUsecaseEvent(
                                    isReload: false,
                                    params: FetchOrdersUsecaseParams(page: orders.pageNumber, status: status),
                                  ),
                                );
                              }
                              return SizedBox(width: 30, height: 30, child: FittedBox(child: CircularProgressIndicator.adaptive(strokeWidth: 3)));
                            }
                            return OrderCard(data: orders.list[index], bloc: context.read<OrdersBloc>(), index: index);
                          },
                          separatorBuilder: (context, index) => SizedBox(height: 16),
                          itemCount: orders.listLength(1),
                        ),
                      );
                    },
                    onTapRetry: () {
                      context.read<OrdersBloc>().add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: orderNotifier.status.value), isReload: true));
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
