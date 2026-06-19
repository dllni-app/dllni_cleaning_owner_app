class DeliveryFeeModel {
  final DeliveryFeeData? data;
  final bool? success;
  final String? message;

  DeliveryFeeModel({this.data, this.success, this.message});

  factory DeliveryFeeModel.fromJson(dynamic json) {
    final map = _toMap(json);
    return DeliveryFeeModel(
      success: _toBool(map['success']),
      message: _toString(map['message']),
      data: map['data'] == null ? null : DeliveryFeeData.fromJson(map['data']),
    );
  }
}

DeliveryFeeModel deliveryFeeModelFromJson(dynamic json) => DeliveryFeeModel.fromJson(json);

class DeliveryFeeData {
  final int? bookingId;
  final double? distanceKm;
  final double? deliveryFee;
  final double? travelFee;
  final double? adminMargin;
  final double? totalPrice;
  final String? currency;

  DeliveryFeeData({
    this.bookingId,
    this.distanceKm,
    this.deliveryFee,
    this.travelFee,
    this.adminMargin,
    this.totalPrice,
    this.currency,
  });

  factory DeliveryFeeData.fromJson(dynamic json) {
    final map = _toMap(json);
    return DeliveryFeeData(
      bookingId: _toInt(_pick(map, const ['bookingId', 'booking_id'])),
      distanceKm: _toDouble(_pick(map, const ['distanceKm', 'distance_km'])),
      deliveryFee: _toDouble(_pick(map, const ['deliveryFee', 'delivery_fee'])),
      travelFee: _toDouble(_pick(map, const ['travelFee', 'travel_fee'])),
      adminMargin: _toDouble(_pick(map, const ['adminMargin', 'admin_margin'])),
      totalPrice: _toDouble(_pick(map, const ['totalPrice', 'total_price'])),
      currency: _toString(map['currency']),
    );
  }
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  return <String, dynamic>{};
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key) && map[key] != null) return map[key];
  }
  return null;
}

String? _toString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
