import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/fetch_extension_requests_usecas_model.dart';

@lazySingleton
class FetchExtensionRequestsUsecasUseCase implements UseCase<FetchExtensionRequestsUsecasModel, FetchExtensionRequestsUsecasParams> {

  final OrdersRepo orders;

  FetchExtensionRequestsUsecasUseCase({required this.orders});

  @override
  DataResponse<FetchExtensionRequestsUsecasModel> call(FetchExtensionRequestsUsecasParams params) {
    return orders.fetchExtensionRequestsUsecas(params);
  }
}

class FetchExtensionRequestsUsecasParams with Params{}
