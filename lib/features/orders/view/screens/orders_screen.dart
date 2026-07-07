import 'dart:async';
import 'dart:convert';

import 'package:common_package/helpers/error_message_formatter.dart';
import 'package:common_package/helpers/pusher_service_logger.dart';
import 'package:common_package/widgets/app_text.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_extension_prompts.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/worker_realtime_orders_sync.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/worker_dispatch_eligibility_model.dart';
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
  Timer? _fallbackRefreshDebounce;

  // المتغير المسؤول عن إدارة دورة حياة الاشتراك لهذه الشاشة
  RealtimeListenerHandle? _workerListenerHandle;

  int? _resolveWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  ({bool? canReceive, String message}) _cachedEligibility() {
    final canReceiveRaw = SharedPreferencesHelper.getData(
      key: 'worker_can_receive_new_requests',
    );
    bool? canReceive;
    if (canReceiveRaw is bool) {
      canReceive = canReceiveRaw;
    } else if (canReceiveRaw != null) {
      final normalized = canReceiveRaw.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') canReceive = true;
      if (normalized == 'false' || normalized == '0') canReceive = false;
    }

    final messageRaw = SharedPreferencesHelper.getData(
      key: 'worker_eligibility_message_ar',
    );
    var message = messageRaw?.toString().trim();

    final cachedModelRaw = SharedPreferencesHelper.getData(
      key: 'worker_dispatch_eligibility',
    );
    if ((message == null || message.isEmpty) && cachedModelRaw != null) {
      try {
        final decoded = cachedModelRaw is String
            ? jsonDecode(cachedModelRaw)
            : cachedModelRaw;
        if (decoded is Map) {
          final model = WorkerDispatchEligibilityModel.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
          message = model.userMessageAr;
          canReceive ??= model.canReceiveNewRequests;
        }
      } catch (_) {}
    }

    return (
      canReceive: canReceive,
      message: (message == null || message.isEmpty)
          ? 'لا يمكن لحسابك استقبال الطلبات الجديدة حالياً.'
          : message,
    );
  }

  FetchOrdersUsecaseParams _assignedOrdersParams({
    required int page,
    String? status,
  }) {
    return FetchOrdersUsecaseParams(
      page: page,
      status: status ?? orderNotifier.status.value,
      assignedToCurrentWorker: true,
    );
  }

  Widget _emptyOrdersWidget(String? status) {
    if ((status ?? '').trim().toLowerCase() == CleaningBookingStatus.pending) {
      final eligibility = _cachedEligibility();
      if (eligibility.canReceive == false) {
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: 40, start: 24, end: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, size: 34),
              const SizedBox(height: 10),
              AppText.labelMedium(
                eligibility.message,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    }

    return AppText.labelMedium('لا يوجد مهام', fontWeight: FontWeight.w400);
  }

  @override
  void initState() {
    super.initState();
    final initialStatus = widget.initialStatus;
    final hasInitialStatus = initialStatus != null && initialStatus.trim().isNotEmpty;
    final firstFetchStatus = hasInitialStatus ? initialStatus : CleaningBookingStatus.workerAssigned;
    orderNotifier.changeStatus(firstFetchStatus);
    _ordersBloc = getIt<OrdersBloc>()
      ..add(
        FetchOrdersUsecaseEvent(
          params: _assignedOrdersParams(page: 1, status: firstFetchStatus),
          isReload: true,
        ),
      );

    _workerId = _resolveWorkerId();
    if (_workerId != null) {
      _initPusher();
    }
  }

  Future<void> _initPusher() async {
    final pusherService = getIt<CleaningBookingPusherService>();
    await pusherService.ensureInitialized();

    if (!mounted) return;

    // الاشتراك باستخدام الخدمة الموحدة وتخزين الـ Handle لإدارته لاحقاً
    _workerListenerHandle = await pusherService.subscribeWorkerChannel(
      workerId: _workerId!,
      onEvent: (eventName, payload) {
        if (!mounted) return;

        final normalizedEvent = CleaningRealtimeContract.normalizeEventName(
          eventName,
        );

        if (normalizedEvent ==
                CleaningRealtimeContract.serviceExtensionRequested ||
            (normalizedEvent ==
                    CleaningRealtimeContract.completionDecisionMade &&
                (payload['decision'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase() ==
                    'extension_requested')) {
          unawaited(
            CleaningWorkerExtensionPrompts.dispatchRealtimeEvent(
              eventName,
              payload,
            ),
          );
        }

        WorkerRealtimeOrdersSync.dispatchSync(
          bloc: _ordersBloc,
          eventName: eventName,
          payload: payload,
        );

        if (CleaningRealtimeContract.isLifecycleRefreshEvent(normalizedEvent)) {
          unawaited(CleaningWorkerExtensionPrompts.pollPendingExtensions());
          if (WorkerRealtimeOrdersSync.prefersListRefetch(
            eventName: eventName,
            payload: payload,
          )) {
            _scheduleFallbackRefresh(reason: 'worker_lifecycle_event_refresh');
          }
        }
      },
      onError: (error) {
        if (error.statusCode != 403) return;
        _scheduleFallbackRefresh(reason: 'worker_channel_auth_403_refresh');
      },
    );
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
      _ordersBloc.add(
        FetchOrdersUsecaseEvent(
          params: _assignedOrdersParams(page: 1),
          isReload: true,
          silent: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _fallbackRefreshDebounce?.cancel();

    // التخلص من الاشتراك بدقة عند الخروج من الشاشة
    unawaited(_workerListenerHandle?.dispose());
    _workerListenerHandle = null;

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
                    emptyWidget: _emptyOrdersWidget(orderNotifier.status.value),
                    failedWidget: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 40),
                      child: Center(
                        child: AppText.labelMedium(
                          ErrorMessageFormatter.format(
                            orders.errorMessage.isNotEmpty
                                ? orders.errorMessage
                                : state.errorMessage,
                            fallback: 'تعذر تحميل المهام',
                          ),
                          fontWeight: FontWeight.w400,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    successWidget: () {
                      return ValueListenableBuilder(
                        valueListenable: orderNotifier.status,
                        builder: (context, status, _) => ListView.separated(
                          padding: const EdgeInsetsDirectional.only(
                            start: 24,
                            end: 24,
                            bottom: 20,
                          ),
                          itemCount: orders.listLength(1),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (orders.length <= index) {
                              if (orders.length == index) {
                                context.read<OrdersBloc>().add(
                                  FetchOrdersUsecaseEvent(
                                    isReload: false,
                                    params: _assignedOrdersParams(
                                      page: orders.pageNumber,
                                      status: status,
                                    ),
                                  ),
                                );
                              }

                              return const SizedBox(
                                width: 30,
                                height: 30,
                                child: FittedBox(
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            }

                            final item = orders.list[index];

                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.03),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: OrderCard(
                                key: ValueKey(item.id),
                                data: item,
                                bloc: context.read<OrdersBloc>(),
                                index: index,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    onTapRetry: () {
                      context.read<OrdersBloc>().add(
                        FetchOrdersUsecaseEvent(
                          params: _assignedOrdersParams(page: 1),
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
