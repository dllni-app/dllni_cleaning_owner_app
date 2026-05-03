import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/update_availability_usecase_model.dart';

@lazySingleton
class UpdateAvailabilityUsecaseUseCase implements UseCase<UpdateAvailabilityUsecaseModel, UpdateAvailabilityUsecaseParams> {

  final OrdersRepo orders;

  UpdateAvailabilityUsecaseUseCase({required this.orders});

  @override
  DataResponse<UpdateAvailabilityUsecaseModel> call(UpdateAvailabilityUsecaseParams params) {
    return orders.updateAvailabilityUsecase(params);
  }
}

class UpdateAvailabilityUsecaseParams with Params {
  UpdateAvailabilityUsecaseParams({required this.id});

  final int id;
}
