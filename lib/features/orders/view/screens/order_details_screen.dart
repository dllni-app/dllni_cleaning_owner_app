import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_extension_prompts.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/screens/main_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_details_to_list_item_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_body.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_mission_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../helpers/order_lifecycle_policy.dart';
import '../manager/bloc/orders_bloc.dart';
import '../widgets/order_details/order_details_map_body.dart';

@AutoRoutePage()
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.params});

  final OrderDetailsScreenParams params;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const Duration _fallbackDebounce = Duration(milliseconds: 150);
  static const Duration _awaitingVerificationPollInterval =
      Duration(seconds: 12);

  late FetchOrdersUsecaseModelDataItem _order;
  final PusherManager _pusherManager = getIt<PusherManager>();
  RealtimeListenerHandle? _bookingListenerHandle;
  RealtimeListenerHandle? _workerListenerHandle;
  Timer? _syncFallbackDebounce;
  Timer? _awaitingVerificationPoll;
  OrdersState? _previousBlocState;
  final Set<String> _handledExtensionDecisionKeys = <String>{};
  bool _extensionRejectedDialogOpen = false;

  int _stepFor(FetchOrdersUsecaseModelDataItem o) =>
      OrderLifecyclePolicy.detailsStepFor(o);

  bool get _isAwaitingStartVerification =>
      OrderLifecyclePolicy.isAwaitingStartVerification(_order);

  bool get _shouldPollLifecycleAdvance =>
      _isAwaitingStartVerification ||
      OrderLifecyclePolicy.isAwaitingWorkerStartConfirmation(_order);

  bool get _canShowMissionBody {
    final status = (_order.status ?? '').trim().toLowerCase();
    return status == CleaningBookingStatus.inProgress ||
        status == CleaningBookingStatus.timeExtensionRequested ||
        status == CleaningBookingStatus.awaitingCustomerCompletion ||
        status == CleaningBookingStatus.underDispute;
  }

  int? _resolveWorkerId() {
    final fromOrder = _order.workerId;
    if (fromOrder != null && fromOrder > 0) return fromOrder;
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  @override
  void initState() {
    super.initState();
    _order = widget.params.order;
    widget.params.bloc.add(ChangeDetailsCurrentStep(step: _stepFor(_order)));
    final id = _order.id;
    if (id != null) {
      widget.params.bloc.add(
        FetchOrderDetailsUsecaseEvent(
          params: FetchOrderDetailsUsecaseParams(id: id),
        ),
      );
      unawaited(_bindRealtimeListeners());
      _syncAwaitingVerificationPoll();
    }
  }

  Future<void> _bindRealtimeListeners() async {
    final bookingId = _order.id;
    if (bookingId == null) return;

    await _detachRealtimeListeners();

    _bookingListenerHandle = await _pusherManager.listen(
      channelName: '${CleaningRealtimeContract.bookingChannelPrefix}$bookingId',
      onEvent: (event) {
        _handleRealtimeEvent(
          eventName: event.eventName,
          payload: event.payload,
          bookingId: bookingId,
          fromWorkerChannel: false,
        );
      },
      onChannelError: _onRealtimeChannelError,
    );

    final workerId = _resolveWorkerId();
    if (workerId != null && workerId > 0) {
      _workerListenerHandle = await _pusherManager.listen(
        channelName: '${CleaningRealtimeContract.workerChannelPrefix}$workerId',
        onEvent: (event) {
          _handleRealtimeEvent(
            eventName: event.eventName,
            payload: event.payload,
            bookingId: bookingId,
            fromWorkerChannel: true,
          );
        },
        onChannelError: _onRealtimeChannelError,
      );
    }

    if (!mounted) {
      await _detachRealtimeListeners();
    }
  }

  Future<void> _detachRealtimeListeners() async {
    final bookingHandle = _bookingListenerHandle;
    final workerHandle = _workerListenerHandle;
    _bookingListenerHandle = null;
    _workerListenerHandle = null;
    await bookingHandle?.dispose();
    await workerHandle?.dispose();
  }

  void _handleRealtimeEvent({
    required String eventName,
    required Map<String, dynamic> payload,
    required int bookingId,
    required bool fromWorkerChannel,
  }) {
    if (!mounted) return;

    final normalizedEvent = CleaningRealtimeContract.normalizeEventName(eventName);
    final payloadBookingId = CleaningRealtimeContract.extractBookingId(payload);

    if (fromWorkerChannel) {
      if (payloadBookingId == null || payloadBookingId != bookingId) return;
    } else if (payloadBookingId != null && payloadBookingId != bookingId) {
      return;
    }

    final isExtensionRequest = normalizedEvent ==
            CleaningRealtimeContract.serviceExtensionRequested ||
        (normalizedEvent == CleaningRealtimeContract.completionDecisionMade &&
            (payload['decision'] ?? '').toString().trim().toLowerCase() ==
                'extension_requested');
    if (isExtensionRequest) {
      unawaited(
        CleaningWorkerExtensionPrompts.dispatchRealtimeEvent(eventName, payload),
      );
    }

    if (normalizedEvent == CleaningRealtimeContract.completionDecisionMade) {
      _maybeShowExtensionRejectedDialog(payload);
    }

    if (CleaningRealtimeContract.isLifecycleRefreshEvent(normalizedEvent)) {
      _scheduleSyncFallback(
        bookingId: bookingId,
        reason: fromWorkerChannel
            ? 'owner_details_worker_lifecycle_event_refresh'
            : 'owner_details_lifecycle_event_refresh',
      );
    }
  }

  void _onRealtimeChannelError(RealtimeChannelError error) {
    if (error.statusCode != 403) return;
    final bookingId = _order.id;
    if (bookingId != null) {
      _scheduleSyncFallback(
        bookingId: bookingId,
        reason: 'owner_details_channel_auth_403_refresh',
      );
    }
  }

  void _scheduleSyncFallback({required int bookingId, required String reason}) {
    if (_order.id != bookingId) return;
    _syncFallbackDebounce?.cancel();
    _syncFallbackDebounce = Timer(_fallbackDebounce, () {
      if (!mounted || _order.id != bookingId) return;
      PusherServiceLogger.event(
        'private-cleaning-booking.$bookingId',
        'CleaningBookingTrackingUpdated',
        const <String, dynamic>{},
        eventHandledAtMs: DateTime.now().millisecondsSinceEpoch,
        fallbackReason: reason,
      );
      widget.params.bloc.add(SyncOrderFromRealtimeEvent(bookingId: bookingId));
    });
  }

  String? _extensionDecisionKey({
    required Map<String, dynamic> payload,
    required int? warningId,
    required String decision,
  }) {
    if (warningId != null) return 'warning_$warningId';
    final unwrapped = CleaningRealtimeContract.unwrapPayload(payload);
    final bookingId = CleaningRealtimeContract.extractBookingId(unwrapped);
    final decidedAt =
        (unwrapped['decidedAt'] ?? unwrapped['decided_at'])?.toString();
    if (bookingId == null) return null;
    return '${bookingId}_${decision}_$decidedAt';
  }

  void _maybeShowExtensionRejectedDialog(Map<String, dynamic> payload) {
    final unwrapped = CleaningRealtimeContract.unwrapPayload(payload);
    final decision = CleaningRealtimeContract.extractDecision(unwrapped);
    if (decision != 'extension_rejected') return;
    final currentStatus = (_order.status ?? '').trim().toLowerCase();
    if (currentStatus != CleaningBookingStatus.timeExtensionRequested) return;

    final warningId = CleaningRealtimeContract.extractWarningId(unwrapped);
    final decisionKey = _extensionDecisionKey(
      payload: unwrapped,
      warningId: warningId,
      decision: decision ?? 'extension_rejected',
    );
    if (decisionKey != null && _handledExtensionDecisionKeys.contains(decisionKey)) {
      return;
    }
    if (decisionKey != null) _handledExtensionDecisionKeys.add(decisionKey);
    unawaited(
      _showExtensionRejectedDialog(
        CleaningRealtimeContract.extractDecisionMessage(unwrapped),
      ),
    );
  }

  Future<void> _showExtensionRejectedDialog(String? message) async {
    if (!mounted || _extensionRejectedDialogOpen) return;
    _extensionRejectedDialogOpen = true;
    try {
      final body = message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'تم رفض طلب تمديد الوقت وتم إنهاء الطلب.';
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('تم إنهاء طلب التمديد', textAlign: TextAlign.center),
            content: Text(body, textAlign: TextAlign.center),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final navigator = Navigator.of(ctx, rootNavigator: true);
                    navigator.pop();
                    navigator.pushNamedAndRemoveUntil(
                      '/main',
                      (route) => false,
                      arguments: MainScreenParam(returnedPageIndex: 0),
                    );
                  },
                  child: const Text('حسناً'),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      _extensionRejectedDialogOpen = false;
    }
  }

  void _syncAwaitingVerificationPoll() {
    if (!mounted) return;
    if (!_shouldPollLifecycleAdvance) {
      _awaitingVerificationPoll?.cancel();
      _awaitingVerificationPoll = null;
      return;
    }
    if (_awaitingVerificationPoll?.isActive == true) return;
    _awaitingVerificationPoll = Timer.periodic(
      _awaitingVerificationPollInterval,
      (_) => _pollOrderDetailsForVerificationAdvance(),
    );
  }

  void _pollOrderDetailsForVerificationAdvance() {
    if (!mounted || !_shouldPollLifecycleAdvance) {
      _awaitingVerificationPoll?.cancel();
      _awaitingVerificationPoll = null;
      return;
    }
    final bookingId = _order.id;
    if (bookingId == null) return;
    widget.params.bloc.add(SyncOrderFromRealtimeEvent(bookingId: bookingId));
  }

  void _applyLifecyclePatch({
    String? status,
    String? arrivedAt,
    String? startedTravelAt,
    String? workStartedAt,
    String? workFinishedAt,
    String? customerConfirmedAt,
  }) {
    if (!mounted) return;

    final resolvedStatus = status != null &&
            OrderLifecyclePolicy.shouldApplyRealtimeStatus(
              currentStatus: _order.status,
              incomingStatus: status,
            )
        ? status
        : _order.status;

    setState(() {
      _order = _order.withLifecycle(
        status: resolvedStatus,
        arrivedAt: arrivedAt,
        startedTravelAt: startedTravelAt,
        workStartedAt: workStartedAt,
        workFinishedAt: workFinishedAt,
        customerConfirmedAt: customerConfirmedAt,
      );
    });
    widget.params.bloc.add(ChangeDetailsCurrentStep(step: _stepFor(_order)));
    _syncAwaitingVerificationPoll();
  }

  FetchOrdersUsecaseModelDataItem _mergeDetailsIntoOrder(
    FetchOrderDetailsUsecaseModelData details,
  ) {
    return OrderDetailsToListItemMapper.fromDetails(details).withTeamData(
      assignmentMode: details.assignmentMode,
      numberOfWorkers: details.numberOfWorkers,
      workerAcceptance: details.workerAcceptance,
      workerAssignments: details.workerAssignments,
      roomAssignments: details.roomAssignments,
      myAssignment: details.myAssignment,
    );
  }

  void _onBlocStateChanged(OrdersState state, OrdersState? previous) {
    final oid = _order.id;
    if (oid == null) return;

    if (previous == null ||
        state.orderDetailsUsecase != previous.orderDetailsUsecase) {
      final details = state.orderDetailsUsecase?.data;
      if (details != null && details.id == oid) {
        if (!mounted) return;
        setState(() {
          _order = _mergeDetailsIntoOrder(details);
        });
        widget.params.bloc.add(ChangeDetailsCurrentStep(step: _stepFor(_order)));
        _syncAwaitingVerificationPoll();
      }
    }

    if (previous == null || state.arrive != previous.arrive) {
      final arrive = state.arrive?.data;
      if (arrive != null && arrive.id == oid) {
        _applyLifecyclePatch(
          status: arrive.status,
          arrivedAt: arrive.arrivedAt,
          startedTravelAt: arrive.startedTravelAt,
          workStartedAt: arrive.workStartedAt,
          workFinishedAt: arrive.workFinishedAt,
          customerConfirmedAt: arrive.customerConfirmedAt,
        );
      }
    }

    if (previous == null || state.startTravelUsecase != previous.startTravelUsecase) {
      final st = state.startTravelUsecase?.data;
      if (st != null && st.id == oid && st.status != null) {
        _applyLifecyclePatch(
          status: st.status,
          startedTravelAt: _order.startedTravelAt ?? DateTime.now().toUtc().toIso8601String(),
        );
      }
    }

    if (previous == null || state.startWork != previous.startWork) {
      final sw = state.startWork?.data;
      if (sw != null && sw.id == oid) {
        _applyLifecyclePatch(status: sw.status, workStartedAt: sw.workStartedAt);
      }
    }

    if (previous == null ||
        state.completeOrderUsecase != previous.completeOrderUsecase) {
      final co = state.completeOrderUsecase?.data;
      if (co != null && co.id == oid) {
        _applyLifecyclePatch(status: co.status, workFinishedAt: co.workFinishedAt);
      }
    }

    if (previous == null || state.acceptOrderUsecase != previous.acceptOrderUsecase) {
      final acc = state.acceptOrderUsecase?.data;
      if (acc != null && acc.id == oid && acc.status != null) {
        _applyLifecyclePatch(status: acc.status);
      }
    }
  }

  @override
  void dispose() {
    _syncFallbackDebounce?.cancel();
    _awaitingVerificationPoll?.cancel();
    unawaited(_detachRealtimeListeners());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      bloc: widget.params.bloc,
      listenWhen: (p, c) =>
          c.orderDetailsUsecase != p.orderDetailsUsecase ||
          c.arrive != p.arrive ||
          c.securityCode != p.securityCode ||
          c.startWork != p.startWork ||
          c.completeOrderUsecase != p.completeOrderUsecase ||
          c.startTravelUsecase != p.startTravelUsecase ||
          c.acceptOrderUsecase != p.acceptOrderUsecase,
      listener: (context, state) {
        final previous = _previousBlocState;
        _previousBlocState = state;
        _onBlocStateChanged(state, previous);
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<OrdersBloc, OrdersState>(
            bloc: widget.params.bloc,
            builder: (context, state) {
              final step = _stepFor(_order);
              if (!_canShowMissionBody && (step == 0 || step == 1)) {
                return OrderDetailsBody(
                  bloc: widget.params.bloc,
                  index: widget.params.index,
                  order: _order,
                );
              }
              if (!_canShowMissionBody && step == 2) {
                return SafeArea(
                  child: OrderDetailsMapBody(
                    order: _order,
                    bloc: widget.params.bloc,
                    index: widget.params.index,
                  ),
                );
              }
              if (!_canShowMissionBody) {
                return OrderDetailsBody(
                  bloc: widget.params.bloc,
                  index: widget.params.index,
                  order: _order,
                );
              }
              return OrderDetailsMissionBody(
                order: _order,
                bloc: widget.params.bloc,
                index: widget.params.index,
                addons: state.arrive?.data?.addons ?? _order.addons ?? [],
                services: state.arrive?.data?.services ?? _order.services ?? [],
              );
            },
          ),
        ),
      ),
    );
  }
}

class OrderDetailsScreenParams {
  final FetchOrdersUsecaseModelDataItem order;
  final bool isNewOrder;
  final OrdersBloc bloc;
  final int index;

  OrderDetailsScreenParams({
    required this.order,
    required this.isNewOrder,
    required this.bloc,
    required this.index,
  });
}
