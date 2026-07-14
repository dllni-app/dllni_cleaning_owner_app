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

  static const String defaultRejectionMessage =
      'رفض العامل طلب تمديد وقت الخدمة.';

  final int id;
  final String? message;

  @override
  BodyMap getBody() {
    final value = message?.trim();
    return <String, dynamic>{
      'message': value == null || value.isEmpty
          ? defaultRejectionMessage
          : value,
    };
  }
}
