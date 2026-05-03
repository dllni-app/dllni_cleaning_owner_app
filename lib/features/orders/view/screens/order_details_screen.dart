import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_body.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/extension_request_action_sheet.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_mission_body.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_verification_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late FetchOrdersUsecaseModelDataItem _order;
  bool _subscribedToRealtime = false;
  int? _lastShownExtensionWarningId;

  int _stepFor(FetchOrdersUsecaseModelDataItem o) {
    if (o.status == CleaningBookingStatus.pending) {
      return 0;
    }
    if (o.status == CleaningBookingStatus.workerAssigned) {
      if (o.startedTravelAt == null) {
        return 1;
      }
      return 2;
    }
    if (o.status == CleaningBookingStatus.awaitingStartVerification) {
      return 4;
    }
    if (o.status == CleaningBookingStatus.inProgress ||
        o.status == CleaningBookingStatus.timeExtensionRequested) {
      return 3;
    }
    if (o.status == CleaningBookingStatus.awaitingCustomerCompletion) {
      return 3;
    }
    return 1;
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
      final pusher = getIt<CleaningBookingPusherService>();
      pusher.setBookingHandler(id, (eventName, payload) {
        if (!mounted) return;
        if (eventName == 'ServiceExtensionRequested') {
          final warningId = payload['warningId'];
          final parsedWarningId = warningId is num
              ? warningId.toInt()
              : int.tryParse('$warningId');
          if (parsedWarningId != null &&
              parsedWarningId != _lastShownExtensionWarningId) {
            _lastShownExtensionWarningId = parsedWarningId;
            final bookingIdRaw = payload['cleaningBookingId'];
            final requestedRaw = payload['requestedMinutes'];
            unawaited(
              ExtensionRequestActionSheet.show(
                context,
                bloc: widget.params.bloc,
                warningId: parsedWarningId,
                bookingId: bookingIdRaw is num
                    ? bookingIdRaw.toInt()
                    : int.tryParse('$bookingIdRaw'),
                requestedMinutes: requestedRaw is num
                    ? requestedRaw.toInt()
                    : int.tryParse('$requestedRaw'),
              ),
            );
          }
        }
        widget.params.bloc.add(SyncOrderFromRealtimeEvent(bookingId: id));
      });
      pusher.subscribeBookingChannel(id);
      _subscribedToRealtime = true;
    }
  }

  @override
  void dispose() {
    if (_subscribedToRealtime) {
      final id = _order.id;
      if (id != null) {
        final pusher = getIt<CleaningBookingPusherService>();
        pusher.setBookingHandler(id, null);
        pusher.unsubscribeBookingChannel(id);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      bloc: widget.params.bloc,
      listenWhen: (p, c) =>
          c.orderDetailsUsecase != p.orderDetailsUsecase ||
          c.arrive != p.arrive ||
          c.startWork != p.startWork ||
          c.completeOrderUsecase != p.completeOrderUsecase ||
          c.startTravelUsecase != p.startTravelUsecase ||
          c.acceptOrderUsecase != p.acceptOrderUsecase,
      listener: (context, state) {
        final oid = _order.id;

        final details = state.orderDetailsUsecase?.data;
        if (details != null && details.id == oid && details.status != null) {
          setState(() {
            _order = _order.withLifecycle(status: details.status);
          });
          widget.params.bloc.add(
            ChangeDetailsCurrentStep(step: _stepFor(_order)),
          );
        }

        final arrive = state.arrive?.data;
        if (arrive != null && arrive.id == oid) {
          setState(() {
            _order = _order.withLifecycle(
              status: arrive.status,
              arrivedAt: arrive.arrivedAt,
              workStartedAt: arrive.workStartedAt,
              workFinishedAt: arrive.workFinishedAt,
              startedTravelAt: arrive.startedTravelAt,
              customerConfirmedAt: arrive.customerConfirmedAt,
            );
          });
          widget.params.bloc.add(
            ChangeDetailsCurrentStep(step: _stepFor(_order)),
          );
        }

        final st = state.startTravelUsecase?.data;
        if (st != null && st.id == oid && st.status != null) {
          setState(() {
            _order = _order.withLifecycle(status: st.status);
          });
          widget.params.bloc.add(
            ChangeDetailsCurrentStep(step: _stepFor(_order)),
          );
        }

        final sw = state.startWork?.data;
        if (sw != null && sw.id == oid) {
          setState(() {
            _order = _order.withLifecycle(
              status: sw.status,
              workStartedAt: sw.workStartedAt,
            );
          });
          widget.params.bloc.add(
            ChangeDetailsCurrentStep(step: _stepFor(_order)),
          );
        }

        final co = state.completeOrderUsecase?.data;
        if (co != null && oid != null && co.id == oid) {
          setState(() {
            _order = _order.withLifecycle(
              status: co.status,
              workFinishedAt: co.workFinishedAt,
            );
          });
          widget.params.bloc.add(
            ChangeDetailsCurrentStep(step: _stepFor(_order)),
          );
        }

        final acc = state.acceptOrderUsecase?.data;
        if (acc != null && acc.id == oid && acc.status != null) {
          setState(() {
            _order = _order.withLifecycle(status: acc.status);
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<OrdersBloc, OrdersState>(
            bloc: widget.params.bloc,
            builder: (context, state) {
              final step = state.currentStep ?? _stepFor(_order);
              if (step == 0) {
                return OrderDetailsBody(
                  bloc: widget.params.bloc,
                  index: widget.params.index,
                  order: _order,
                  isNewOrder: widget.params.isNewOrder,
                );
              }
              if (step == 1) {
                return OrderDetailsBody(
                  bloc: widget.params.bloc,
                  index: widget.params.index,
                  order: _order,
                  isNewOrder: false,
                );
              }
              if (step == 2) {
                return SafeArea(
                  child: OrderDetailsMapBody(
                    order: _order,
                    bloc: widget.params.bloc,
                  ),
                );
              }
              if (step == 4) {
                return OrderDetailsVerificationBody(
                  order: _order,
                  bloc: widget.params.bloc,
                );
              }
              return OrderDetailsMissionBody(
                order: _order,
                bloc: widget.params.bloc,
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
