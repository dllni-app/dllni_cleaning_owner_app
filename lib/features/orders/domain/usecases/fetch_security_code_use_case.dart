import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/security_code_model.dart';

@lazySingleton
class FetchSecurityCodeUseCase implements UseCase<SecurityCodeModel, FetchSecurityCodeParams> {
  FetchSecurityCodeUseCase({required this.orders});

  final OrdersRepo orders;

  @override
  DataResponse<SecurityCodeModel> call(FetchSecurityCodeParams params) {
    return orders.fetchSecurityCode(params);
  }
}

class FetchSecurityCodeParams with Params {
  FetchSecurityCodeParams({required this.id});

  final int id;
}
