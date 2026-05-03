import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/booking_location_model.dart';

@lazySingleton
class PostBookingLocationUseCase implements UseCase<BookingLocationOkModel, PostBookingLocationParams> {
  PostBookingLocationUseCase({required this.orders});

  final OrdersRepo orders;

  @override
  DataResponse<BookingLocationOkModel> call(PostBookingLocationParams params) {
    return orders.postBookingLocation(params);
  }
}

class PostBookingLocationParams with Params {
  PostBookingLocationParams({required this.id, required this.latitude, required this.longitude});

  final int id;
  final double latitude;
  final double longitude;

  @override
  BodyMap getBody() => {'latitude': latitude, 'longitude': longitude};
}
