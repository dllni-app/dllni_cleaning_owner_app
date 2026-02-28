import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/complete_order_usecase_model.dart';

@lazySingleton
class CompleteOrderUsecaseUseCase implements UseCase<CompleteOrderUsecaseModel, CompleteOrderUsecaseParams> {

  final OrdersRepo orders;

  CompleteOrderUsecaseUseCase({required this.orders});

  @override
  DataResponse<CompleteOrderUsecaseModel> call(CompleteOrderUsecaseParams params) {
    return orders.completeOrderUsecase(params);
  }
}

class CompleteOrderUsecaseParams with Params{}
