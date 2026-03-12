import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/arrive_model.dart';

@lazySingleton
class ArriveUseCase implements UseCase<ArriveModel, ArriveParams> {

  final OrdersRepo orders;

  ArriveUseCase({required this.orders});

  @override
  DataResponse<ArriveModel> call(ArriveParams params) {
    return orders.arrive(params);
  }
}

class ArriveParams with Params{
  final int id;

  ArriveParams({required this.id});
}
