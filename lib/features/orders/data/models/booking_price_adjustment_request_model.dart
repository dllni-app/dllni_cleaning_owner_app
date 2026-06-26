import 'dart:convert';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) continue;
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

BookingPriceAdjustmentRequestModel bookingPriceAdjustmentRequestModelFromJson(
  dynamic json,
) {
  final map = json is String ? _asMap(jsonDecode(json)) : _asMap(json);
  return BookingPriceAdjustmentRequestModel.fromJson(map);
}

class BookingPriceAdjustmentRequestModel {
  const BookingPriceAdjustmentRequestModel({this.data, this.message});

  final BookingPriceAdjustmentRequestData? data;
  final String? message;

  factory BookingPriceAdjustmentRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawData = json['data'];
    return BookingPriceAdjustmentRequestModel(
      data: rawData == null
          ? null
          : BookingPriceAdjustmentRequestData.fromJson(_asMap(rawData)),
      message: _asString(json['message']),
    );
  }
}

class BookingPriceAdjustmentRequestData {
  const BookingPriceAdjustmentRequestData({
    this.id,
    this.cleaningBookingId,
    this.workerId,
    this.currentTotalPrice,
    this.proposedTotalPrice,
    this.reason,
    this.status,
    this.createdAt,
  });

  final int? id;
  final int? cleaningBookingId;
  final int? workerId;
  final double? currentTotalPrice;
  final double? proposedTotalPrice;
  final String? reason;
  final String? status;
  final String? createdAt;

  factory BookingPriceAdjustmentRequestData.fromJson(Map<String, dynamic> json) {
    return BookingPriceAdjustmentRequestData(
      id: _asInt(_pick(json, const <String>['id'])),
      cleaningBookingId: _asInt(
        _pick(json, const <String>[
          'cleaningBookingId',
          'cleaning_booking_id',
          'bookingId',
          'booking_id',
        ]),
      ),
      workerId: _asInt(_pick(json, const <String>['workerId', 'worker_id'])),
      currentTotalPrice: _asDouble(
        _pick(json, const <String>[
          'currentTotalPrice',
          'current_total_price',
          'currentPrice',
          'current_price',
        ]),
      ),
      proposedTotalPrice: _asDouble(
        _pick(json, const <String>[
          'proposedTotalPrice',
          'proposed_total_price',
          'proposedPrice',
          'proposed_price',
        ]),
      ),
      reason: _asString(_pick(json, const <String>['reason'])),
      status: _asString(_pick(json, const <String>['status'])),
      createdAt: _asString(_pick(json, const <String>['createdAt', 'created_at'])),
    );
  }
}
