import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/accept_order_usecase_model.dart';

@lazySingleton
class AcceptOrderUsecaseUseCase implements UseCase<AcceptOrderUsecaseModel, AcceptOrderUsecaseParams> {

  final OrdersRepo orders;

  AcceptOrderUsecaseUseCase({required this.orders});

  @override
  DataResponse<AcceptOrderUsecaseModel> call(AcceptOrderUsecaseParams params) {
    return orders.acceptOrderUsecase(params);
  }
}

class AcceptOrderUsecaseParams with Params{
  final int id;

  AcceptOrderUsecaseParams({required this.id});
}
