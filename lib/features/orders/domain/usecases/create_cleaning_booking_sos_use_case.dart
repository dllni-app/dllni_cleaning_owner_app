import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/sos_alert_models.dart';
import '../repository/orders_repo.dart';

@lazySingleton
class CreateCleaningBookingSosUseCase
    implements UseCase<CleaningSosAlertModel, CreateCleaningBookingSosParams> {
  final OrdersRepo orders;

  CreateCleaningBookingSosUseCase({required this.orders});

  @override
  DataResponse<CleaningSosAlertModel> call(
    CreateCleaningBookingSosParams params,
  ) {
    return orders.createCleaningBookingSos(params);
  }
}

class CreateCleaningBookingSosParams with Params {
  final int orderId;
  final String emergencyType;
  final String message;
  final double? latitude;
  final double? longitude;

  CreateCleaningBookingSosParams({
    required this.orderId,
    required this.emergencyType,
    required this.message,
    this.latitude,
    this.longitude,
  });

  @override
  BodyMap getBody() {
    final body = <String, dynamic>{
      'order_id': orderId,
      'emergency_type': emergencyType,
      'message': message.trim(),
    };
    if (latitude != null && longitude != null) {
      body['lat'] = latitude;
      body['lng'] = longitude;
    }
    return body;
  }
}
