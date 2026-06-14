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
  final int bookingId;
  final String emergencyType;
  final String? message;
  final double? latitude;
  final double? longitude;
  final String clientRequestId;

  CreateCleaningBookingSosParams({
    required this.bookingId,
    required this.emergencyType,
    this.message,
    this.latitude,
    this.longitude,
    required this.clientRequestId,
  });

  @override
  BodyMap getBody() {
    final body = <String, dynamic>{
      'emergencyType': emergencyType,
      'clientRequestId': clientRequestId,
    };
    final trimmedMessage = message?.trim();
    if (trimmedMessage != null && trimmedMessage.isNotEmpty) {
      body['message'] = trimmedMessage;
    }
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }
    return body;
  }
}
