import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/start_travel_usecase_model.dart';

@lazySingleton
class StartTravelUsecaseUseCase implements UseCase<StartTravelUsecaseModel, StartTravelUsecaseParams> {

  final OrdersRepo orders;

  StartTravelUsecaseUseCase({required this.orders});

  @override
  DataResponse<StartTravelUsecaseModel> call(StartTravelUsecaseParams params) {
    return orders.startTravelUsecase(params);
  }
}

class StartTravelUsecaseParams with Params{
  final int id;

  StartTravelUsecaseParams({required this.id});
}
