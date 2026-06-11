import '../../data/models/fetch_order_details_usecase_model.dart';
import '../../data/models/fetch_orders_usecase_model.dart';

/// Maps order-details API data to the list-item shape used on the home screen.
class OrderDetailsToListItemMapper {
  OrderDetailsToListItemMapper._();

  static FetchOrdersUsecaseModelDataItem fromDetails(
    FetchOrderDetailsUsecaseModelData details,
  ) {
    final json = Map<String, dynamic>.from(details.toJson());
    final worker = details.worker;
    if (worker != null) {
      json['worker'] = <String, dynamic>{
        'id': worker.id,
        'firstName': worker.name,
        'phone': worker.phone,
        'averageRating': worker.averageRating,
        'avatarUrl': worker.avatarUrl,
      };
    }
    return FetchOrdersUsecaseModelDataItem.fromJson(json);
  }
}
