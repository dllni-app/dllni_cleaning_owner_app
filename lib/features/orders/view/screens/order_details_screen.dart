import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_body.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/widgets/order_details/order_details_mission_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/fetch_orders_usecase_model.dart';
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
  List<String> titles = ['إجمالي عدد\nساعات العمل', 'المساحة\nالتقديرية', 'السعر\nالإجمالي'];
  List<String> val = [];

  int step() {
    if (widget.params.order.status == 'pending') {
      return 0;
    } else if (widget.params.order.status == 'worker_assigned') {
      return 1;
    } else if (widget.params.order.startedTravelAt != null) {
      return 2;
    } else if (widget.params.order.status == 'in_progress') {
      return 3;
    } else {
      return 1;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.params.bloc.add(ChangeDetailsCurrentStep(step: step()));
    val = [widget.params.order.totalHours.toString(), widget.params.order.estimatedSqm.toString(), '\$${widget.params.order.totalPrice.toString()}'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<OrdersBloc, OrdersState>(
          bloc: widget.params.bloc,
          builder: (context, state) {
            if (state.currentStep == 0) {
              return OrderDetailsBody(
                bloc: widget.params.bloc,
                index: widget.params.index,
                order: widget.params.order,
                isNewOrder: widget.params.isNewOrder,
              );
            } else if (state.currentStep == 1) {
              return OrderDetailsBody(bloc: widget.params.bloc, index: widget.params.index, order: widget.params.order, isNewOrder: false);
            } else if (state.currentStep == 2) {
              return SafeArea(
                child: OrderDetailsMapBody(order: widget.params.order, bloc: widget.params.bloc),
              );
            } else {
              return OrderDetailsMissionBody(
                order: widget.params.order,
                bloc: widget.params.bloc,
                addons: state.arrive?.data?.addons == null ? [] : state.arrive!.data!.addons!,
                services: state.arrive?.data?.services == null ? [] : state.arrive!.data!.services!,
              );
            }
          },
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

  OrderDetailsScreenParams({required this.order, required this.isNewOrder, required this.bloc, required this.index});
}
