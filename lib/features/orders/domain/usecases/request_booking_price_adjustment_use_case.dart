import 'package:common_package/helpers/typedef.dart';

import '../../data/models/booking_price_adjustment_request_model.dart';
import '../repository/orders_repo.dart';

class RequestBookingPriceAdjustmentUseCase
    implements
        UseCase<
          BookingPriceAdjustmentRequestModel,
          RequestBookingPriceAdjustmentParams
        > {
  RequestBookingPriceAdjustmentUseCase({required this.orders});

  final OrdersRepo orders;

  @override
  DataResponse<BookingPriceAdjustmentRequestModel> call(
    RequestBookingPriceAdjustmentParams params,
  ) {
    return orders.requestBookingPriceAdjustment(params);
  }
}

class RequestBookingPriceAdjustmentParams with Params {
  RequestBookingPriceAdjustmentParams({
    required this.id,
    required this.proposedTotalPrice,
    this.reason,
  });

  final int id;
  final double proposedTotalPrice;
  final String? reason;

  @override
  BodyMap getBody() {
    final trimmedReason = reason?.trim();
    return <String, dynamic>{
      'proposed_total_price': proposedTotalPrice,
      if (trimmedReason != null && trimmedReason.isNotEmpty)
        'reason': trimmedReason,
    };
  }
}
