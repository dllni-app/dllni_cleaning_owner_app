import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/accept_extension_usecase_model.dart';

@lazySingleton
class AcceptExtensionUsecaseUseCase implements UseCase<AcceptExtensionUsecaseModel, AcceptExtensionUsecaseParams> {

  final OrdersRepo orders;

  AcceptExtensionUsecaseUseCase({required this.orders});

  @override
  DataResponse<AcceptExtensionUsecaseModel> call(AcceptExtensionUsecaseParams params) {
    return orders.acceptExtensionUsecase(params);
  }
}

class AcceptExtensionUsecaseParams with Params{}
