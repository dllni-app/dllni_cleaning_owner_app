import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/complete_order_usecase_model.dart';

@lazySingleton
class CompleteOrderUsecaseUseCase implements UseCase<CompleteOrderUsecaseModel, CompleteOrderUsecaseParams> {
  final OrdersRepo orders;

  CompleteOrderUsecaseUseCase({required this.orders});

  @override
  DataResponse<CompleteOrderUsecaseModel> call(CompleteOrderUsecaseParams params) {
    return orders.completeOrderUsecase(params);
  }
}

class CompleteOrderUsecaseParams with Params {
  CompleteOrderUsecaseParams({
    required this.id,
    this.completionMessage,
    this.cleaningServices = const [],
    this.propertiesRooms = const [],
  });

  final int id;
  final String? completionMessage;
  final List<Map<String, Object?>> cleaningServices;
  final List<Map<String, Object?>> propertiesRooms;

  @override
  Map<String, dynamic> getBody() {
    final message = completionMessage?.trim();
    return {
      if (message != null && message.isNotEmpty) 'completionMessage': message,
      'cleaning_services': cleaningServices,
      'propertiesRooms': propertiesRooms,
    };
  }
}
