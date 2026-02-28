import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/cancel_order_details_model.dart';

@lazySingleton
class CancelOrderUseCase implements UseCase<CancelOrderModel, CancelOrderParams> {

  final OrdersRepo orders;

  CancelOrderUseCase({required this.orders});

  @override
  DataResponse<CancelOrderModel> call(CancelOrderParams params) {
    return orders.cancelOrder(params);
  }
}

class CancelOrderParams with Params{
  final int id;

  CancelOrderParams({required this.id});
}
