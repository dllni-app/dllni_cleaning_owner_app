import '../../data/models/fetch_order_details_usecase_model.dart';
import '../../data/models/fetch_orders_usecase_model.dart';

/// Maps order-details API data to the list-item shape used on the home screen.
class OrderDetailsToListItemMapper {
  OrderDetailsToListItemMapper._();

  static FetchOrdersUsecaseModelDataItem fromDetails(
    FetchOrderDetailsUsecaseModelData details, {
    FetchOrdersUsecaseModelDataItem? fallback,
  }) {
    final json = <String, dynamic>{
      if (fallback != null) ..._withoutEmptyValues(fallback.toJson()),
      ..._withoutEmptyValues(details.toJson()),
    };

    final fallbackPropertyDetails = fallback?.propertyDetails?.toJson();
    final detailsPropertyDetails = details.propertyDetails?.toJson();
    final mergedPropertyDetails = <String, dynamic>{
      if (fallbackPropertyDetails != null)
        ..._withoutEmptyValues(fallbackPropertyDetails),
      if (detailsPropertyDetails != null)
        ..._withoutEmptyValues(detailsPropertyDetails),
    };
    if (mergedPropertyDetails.isNotEmpty) {
      json['propertyDetails'] = mergedPropertyDetails;
    }

    if ((details.services?.isNotEmpty ?? false) == false &&
        (fallback?.services?.isNotEmpty ?? false)) {
      json['services'] = fallback!.services!
          .map((service) => service.toJson())
          .toList(growable: false);
    }

    if ((details.addons?.isNotEmpty ?? false) == false &&
        (fallback?.addons?.isNotEmpty ?? false)) {
      json['addons'] = fallback!.addons!
          .map((addon) => addon.toJson())
          .toList(growable: false);
    }

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

  static Map<String, dynamic> _withoutEmptyValues(Map<String, dynamic> values) {
    final result = <String, dynamic>{};
    values.forEach((key, value) {
      if (value == null) return;
      if (value is List && value.isEmpty) return;
      if (value is Map && value.isEmpty) return;
      result[key] = value;
    });
    return result;
  }
}
