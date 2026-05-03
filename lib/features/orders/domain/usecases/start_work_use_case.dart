import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/start_work_model.dart';

@lazySingleton
class StartWorkUseCase implements UseCase<StartWorkModel, StartWorkParams> {
  StartWorkUseCase({required this.orders});

  final OrdersRepo orders;

  @override
  DataResponse<StartWorkModel> call(StartWorkParams params) {
    return orders.startWork(params);
  }
}

class StartWorkParams with Params {
  StartWorkParams({required this.id});

  final int id;
}
