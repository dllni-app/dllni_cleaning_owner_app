import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_extension_prompts.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/arrive_model.dart'
    show Addon, Service;
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_order_details_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_details_to_list_item_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_body.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_mission_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controllers/order_details_lifecycle_poller.dart';
import '../helpers/order_lifecycle_policy.dart';
import '../manager/bloc/orders_bloc.dart';
import '../presenters/order_details_extension_decision_presenter.dart';
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

  late FetchOrdersUsecaseModelDataItem _order;
  late final OrderDetailsLifecyclePoller _lifecyclePoller;
  final PusherManager _pusherManager = getIt<PusherManager>();
  final OrderDetailsExtensionDecisionPresenter _extensionDecisionPresenter =
      OrderDetailsExtensionDecisionPresenter();
  RealtimeListenerHandle? _bookingListenerHandle;
  RealtimeListenerHandle? _workerListenerHandle;
  Timer? _syncFallbackDebounce;
  OrdersState? _previousBlocState;
  String? _lastShownCustomerNoteKey;

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
    _lifecyclePoller = OrderDetailsLifecyclePoller(
      shouldPoll: () => mounted && _shouldPollLifecycleAdvance,
      onPoll: _pollOrderDetailsForVerificationAdvance,
    );
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
      _extensionDecisionPresenter.maybeShowExtensionRejectedDialog(
        context: context,
        order: _order,
        payload: payload,
      );
      _showCustomerCompletionNoteIfNeeded(
        bookingId: bookingId,
        payload: payload,
      );
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

  void _showCustomerCompletionNoteIfNeeded({
    required int bookingId,
    required Map<String, dynamic> payload,
  }) {
    final decision = (payload['decision'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (decision != 'rejected') return;

    final rawMessage = payload['message'] ??
        payload['reason'] ??
        payload['customerMessage'] ??
        payload['customer_message'];
    final message = rawMessage?.toString().trim();
    if (message == null || message.isEmpty) return;

    final decidedAt = payload['decidedAt'] ??
        payload['decided_at'] ??
        payload['updatedAt'] ??
        payload['updated_at'] ??
        '';
    final noteKey = '$bookingId:$decidedAt:$message';
    if (_lastShownCustomerNoteKey == noteKey) return;
    _lastShownCustomerNoteKey = noteKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ملاحظة العميل'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    });
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

  void _syncAwaitingVerificationPoll() {
    if (!mounted) return;
    _lifecyclePoller.sync();
  }

  void _pollOrderDetailsForVerificationAdvance() {
    if (!mounted || !_shouldPollLifecycleAdvance) {
      _lifecyclePoller.stop();
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
    return OrderDetailsToListItemMapper.fromDetails(
      details,
      fallback: _order,
    ).withTeamData(
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
          startedTravelAt:
              _order.startedTravelAt ?? DateTime.now().toUtc().toIso8601String(),
        );
      }
    }

    if (previous == null || state.startWork != previous.startWork) {
      final sw = state.startWork?.data;
      if (sw != null && sw.id == oid) {
        _applyLifecyclePatch(
          status: sw.status,
          workStartedAt: sw.workStartedAt,
        );
      }
    }

    if (previous == null ||
        state.completeOrderUsecase != previous.completeOrderUsecase) {
      final co = state.completeOrderUsecase?.data;
      if (co != null && co.id == oid) {
        _applyLifecyclePatch(
          status: co.status,
          workFinishedAt: co.workFinishedAt,
        );
      }
    }

    if (previous == null || state.acceptOrderUsecase != previous.acceptOrderUsecase) {
      final acc = state.acceptOrderUsecase?.data;
      if (acc != null && acc.id == oid && acc.status != null) {
        _applyLifecyclePatch(status: acc.status);
      }
    }
  }

  List<T> _preferNonEmpty<T>(
    List<T>? first,
    List<T>? second,
    List<T>? third,
  ) {
    if (first != null && first.isNotEmpty) return first;
    if (second != null && second.isNotEmpty) return second;
    if (third != null && third.isNotEmpty) return third;
    return <T>[];
  }

  @override
  void dispose() {
    _syncFallbackDebounce?.cancel();
    _lifecyclePoller.dispose();
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
                addons: _preferNonEmpty<Addon>(
                  state.arrive?.data?.addons,
                  state.orderDetailsUsecase?.data?.addons,
                  _order.addons,
                ),
                services: _preferNonEmpty<Service>(
                  state.arrive?.data?.services,
                  state.orderDetailsUsecase?.data?.services,
                  _order.services,
                ),
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
