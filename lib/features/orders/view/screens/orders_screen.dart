import 'dart:async';

import 'package:common_package/helpers/pusher_service_logger.dart';
import 'package:common_package/widgets/app_text.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
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
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const Duration _fallbackDebounce = Duration(milliseconds: 150);

  final OrderNotifier orderNotifier = OrderNotifier();
  late final OrdersBloc _ordersBloc;
  int? _workerId;
  Timer? _fallbackRefreshDebounce;

  int? _resolveWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  @override
  void initState() {
    super.initState();
    _ordersBloc = getIt<OrdersBloc>()
      ..add(
        FetchOrdersUsecaseEvent(
          params: FetchOrdersUsecaseParams(
            page: 1,
            status: CleaningBookingStatus.pending,
          ),
          isReload: true,
        ),
      );
    _workerId = _resolveWorkerId();
    if (_workerId != null) {
      final pusher = getIt<CleaningBookingPusherService>();
      pusher.setWorkerHandler(_workerId!, (eventName, payload) {
        if (!mounted) return;
        final hydrated = _dispatchRealtimeListHydration(
          eventName: eventName,
          payload: payload,
        );
        if (!hydrated) {
          _scheduleFallbackRefresh();
        }
      });
      unawaited(pusher.subscribeWorkerChannel(_workerId!));
    }
  }

  bool _dispatchRealtimeListHydration({
    required String eventName,
    required Map<String, dynamic> payload,
  }) {
    if (eventName != 'ArrivalVerified' &&
        eventName != 'CompletionDecisionMade' &&
        eventName != 'ServiceExtensionRequested' &&
        eventName != 'CleaningBookingTrackingUpdated' &&
        eventName != 'WorkerArrived' &&
        eventName != 'cleaning_order.awaiting_start_verification' &&
        eventName != 'cleaning_order.awaiting_customer_completion') {
      return false;
    }
    final hasHydratablePayload =
        payload['tracking'] is Map ||
        payload['cleaningBookingId'] != null ||
        payload['bookingId'] != null ||
        payload['booking_id'] != null ||
        payload['id'] != null ||
        payload['status'] != null ||
        payload['decision'] != null;
    if (!hasHydratablePayload) return false;
    _ordersBloc.add(
      HydrateOrderListFromRealtimeEvent(eventName: eventName, payload: payload),
    );
    return true;
  }

  void _scheduleFallbackRefresh() {
    _fallbackRefreshDebounce?.cancel();
    _fallbackRefreshDebounce = Timer(_fallbackDebounce, () {
      if (!mounted) return;
      PusherServiceLogger.event(
        'private-cleaning-worker.${_workerId ?? ''}',
        'CleaningBookingTrackingUpdated',
        <String, dynamic>{'status': orderNotifier.status.value},
        eventHandledAtMs: DateTime.now().millisecondsSinceEpoch,
        fallbackReason: 'missing_owner_orders_payload_fields',
      );
      _ordersBloc.add(
        FetchOrdersUsecaseEvent(
          params: FetchOrdersUsecaseParams(
            page: 1,
            status: orderNotifier.status.value,
          ),
          isReload: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _fallbackRefreshDebounce?.cancel();
    if (_workerId != null) {
      final pusher = getIt<CleaningBookingPusherService>();
      pusher.setWorkerHandler(_workerId!, null);
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
                buildWhen: (previous, current) =>
                    previous.ordersUsecase != current.ordersUsecase,
                builder: (context, state) {
                  return state.ordersUsecase!.builder(
                    loadingWidget: Padding(
                      padding: EdgeInsetsDirectional.only(top: 40),
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    ),
                    emptyWidget: AppText.labelMedium(
                      'لا يوجد مهام',
                      fontWeight: FontWeight.w400,
                    ),
                    successWidget: () {
                      return ValueListenableBuilder(
                        valueListenable: orderNotifier.status,
                        builder: (context, status, _) => ListView.separated(
                          padding: EdgeInsetsDirectional.only(
                            start: 24,
                            end: 24,
                            bottom: 20,
                          ),
                          itemBuilder: (context, index) {
                            if (state.ordersUsecase!.length <= index) {
                              if (state.ordersUsecase!.length == index) {
                                context.read<OrdersBloc>().add(
                                  FetchOrdersUsecaseEvent(
                                    isReload: false,
                                    params: FetchOrdersUsecaseParams(
                                      page: state.ordersUsecase!.pageNumber,
                                      status: status,
                                    ),
                                  ),
                                );
                              }
                              return SizedBox(
                                width: 30,
                                height: 30,
                                child: FittedBox(
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            }
                            return OrderCard(
                              data: state.ordersUsecase!.list[index],
                              bloc: context.read<OrdersBloc>(),
                              index: index,
                            );
                          },
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 16),
                          itemCount: state.ordersUsecase!.listLength(1),
                        ),
                      );
                    },
                    onTapRetry: () {
                      context.read<OrdersBloc>().add(
                        FetchOrdersUsecaseEvent(
                          params: FetchOrdersUsecaseParams(
                            page: 1,
                            status: CleaningBookingStatus.workerAssigned,
                          ),
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
      ),
    );
  }
}
