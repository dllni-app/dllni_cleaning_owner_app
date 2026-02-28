import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/reject_order_usecase_model.dart';

@lazySingleton
class RejectOrderUsecaseUseCase implements UseCase<RejectOrderUsecaseModel, RejectOrderUsecaseParams> {

  final OrdersRepo orders;

  RejectOrderUsecaseUseCase({required this.orders});

  @override
  DataResponse<RejectOrderUsecaseModel> call(RejectOrderUsecaseParams params) {
    return orders.rejectOrderUsecase(params);
  }
}

class RejectOrderUsecaseParams with Params{
  final int id;

  RejectOrderUsecaseParams({required this.id});
}
