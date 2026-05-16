import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/reject_extension_usecase_model.dart';

@lazySingleton
class RejectExtensionUsecaseUseCase implements UseCase<RejectExtensionUsecaseModel, RejectExtensionUsecaseParams> {

  final OrdersRepo orders;

  RejectExtensionUsecaseUseCase({required this.orders});

  @override
  DataResponse<RejectExtensionUsecaseModel> call(RejectExtensionUsecaseParams params) {
    return orders.rejectExtensionUsecase(params);
  }
}

class RejectExtensionUsecaseParams with Params {
  RejectExtensionUsecaseParams({required this.id, this.message});

  final int id;
  final String? message;

  @override
  BodyMap getBody() {
    final value = message?.trim();
    if (value == null || value.isEmpty) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{'message': value};
  }
}
