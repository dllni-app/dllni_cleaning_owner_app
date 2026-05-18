import 'dart:convert';

import 'arrive_model.dart';

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value.map((item) => _toMap(item)).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<dynamic>? _toDynamicList(dynamic value) {
  if (value is! List) return null;
  return value
      .map((item) {
        if (item is Map) return _toMap(item);
        return item;
      })
      .toList(growable: false);
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
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

String? _toStringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

Map<String, dynamic> _withTracking(Map<String, dynamic> json) {
  final tracking = json['tracking'];
  if (tracking is Map) {
    return <String, dynamic>{...json, ..._toMap(tracking)};
  }
  return json;
}

FetchOrderDetailsUsecaseModel fetchOrderDetailsUsecaseModelFromJson(
  dynamic json,
) => FetchOrderDetailsUsecaseModel.fromJson(_toMap(json));

String fetchOrderDetailsUsecaseModelToJson(
  FetchOrderDetailsUsecaseModel data,
) => jsonEncode(data.toJson());

FetchOrderDetailsUsecaseModelData fetchOrderDetailsUsecaseModelDataFromJson(
  dynamic json,
) => FetchOrderDetailsUsecaseModelData.fromJson(_toMap(json));

String fetchOrderDetailsUsecaseModelDataToJson(
  FetchOrderDetailsUsecaseModelData data,
) => jsonEncode(data.toJson());

FetchOrderDetailsUsecaseModelDataBillingPolicy
fetchOrderDetailsUsecaseModelDataBillingPolicyFromJson(dynamic json) =>
    FetchOrderDetailsUsecaseModelDataBillingPolicy.fromJson(_toMap(json));

String fetchOrderDetailsUsecaseModelDataBillingPolicyToJson(
  FetchOrderDetailsUsecaseModelDataBillingPolicy data,
) => jsonEncode(data.toJson());

FetchOrderDetailsUsecaseModelDataWorker
fetchOrderDetailsUsecaseModelDataWorkerFromJson(dynamic json) =>
    FetchOrderDetailsUsecaseModelDataWorker.fromJson(_toMap(json));

String fetchOrderDetailsUsecaseModelDataWorkerToJson(
  FetchOrderDetailsUsecaseModelDataWorker data,
) => jsonEncode(data.toJson());

FetchOrderDetailsUsecaseModelDataCustomer
fetchOrderDetailsUsecaseModelDataCustomerFromJson(dynamic json) =>
    FetchOrderDetailsUsecaseModelDataCustomer.fromJson(_toMap(json));

String fetchOrderDetailsUsecaseModelDataCustomerToJson(
  FetchOrderDetailsUsecaseModelDataCustomer data,
) => jsonEncode(data.toJson());

class FetchOrderDetailsUsecaseModel {
  final FetchOrderDetailsUsecaseModelData? data;

  FetchOrderDetailsUsecaseModel({this.data});

  factory FetchOrderDetailsUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchOrderDetailsUsecaseModel(
      data: json['data'] == null
          ? null
          : FetchOrderDetailsUsecaseModelData.fromJson(_toMap(json['data'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'data': data?.toJson()};
  }
}

class FetchOrderDetailsUsecaseModelData {
  final int? id;
  final int? customerId;
  final int? workerId;
  final int? preferredWorkerId;
  final int? cancellationPolicyId;
  final int? billingPolicyId;

  final String? bookingNumber;
  final String? status;
  final String? propertyType;
  final String? locationName;
  final String? estimatedSqm;
  final String? scheduledDate;
  final String? scheduledTime;
  final String? createdAt;
  final String? updatedAt;

  final int? numberOfRooms;
  final int? numberOfKitchens;
  final double? estimatedHours;
  final double? totalHours;

  final double? basePrice;
  final double? addonsTotal;
  final double? travelFee;
  final double? cancellationFee;
  final double? totalPrice;

  final double? addressLatitude;
  final double? addressLongitude;

  final bool? termsAccepted;

  final String? startedTravelAt;
  final String? arrivedAt;
  final String? workStartedAt;
  final String? workFinishedAt;
  final String? customerConfirmedAt;
  final String? cancelledAt;
  final String? cancellationReason;

  final FetchOrderDetailsUsecaseModelDataCustomer? customer;
  final FetchOrderDetailsUsecaseModelDataWorker? worker;
  final FetchOrderDetailsUsecaseModelDataPropertyDetails? propertyDetails;

  final List<Service>? services;
  final List<Addon>? addons;
  final FetchOrderDetailsUsecaseModelDataBillingPolicy? billingPolicy;
  final List<dynamic>? timeWarnings;
  final List<dynamic>? disputes;

  FetchOrderDetailsUsecaseModelData({
    this.id,
    this.customerId,
    this.workerId,
    this.preferredWorkerId,
    this.cancellationPolicyId,
    this.billingPolicyId,
    this.bookingNumber,
    this.status,
    this.propertyType,
    this.locationName,
    this.estimatedSqm,
    this.scheduledDate,
    this.scheduledTime,
    this.createdAt,
    this.updatedAt,
    this.numberOfRooms,
    this.numberOfKitchens,
    this.estimatedHours,
    this.totalHours,
    this.basePrice,
    this.addonsTotal,
    this.travelFee,
    this.cancellationFee,
    this.totalPrice,
    this.addressLatitude,
    this.addressLongitude,
    this.termsAccepted,
    this.startedTravelAt,
    this.arrivedAt,
    this.workStartedAt,
    this.workFinishedAt,
    this.customerConfirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.customer,
    this.worker,
    this.propertyDetails,
    this.services,
    this.addons,
    this.billingPolicy,
    this.timeWarnings,
    this.disputes,
  });

  factory FetchOrderDetailsUsecaseModelData.fromJson(
    Map<String, dynamic> json,
  ) {
    final m = _withTracking(json);
    return FetchOrderDetailsUsecaseModelData(
      id: _toInt(_pick(m, const <String>['id'])),
      customerId: _toInt(_pick(m, const <String>['customerId', 'customer_id'])),
      workerId: _toInt(_pick(m, const <String>['workerId', 'worker_id'])),
      preferredWorkerId: _toInt(
        _pick(m, const <String>['preferredWorkerId', 'preferred_worker_id']),
      ),
      cancellationPolicyId: _toInt(
        _pick(m, const <String>[
          'cancellationPolicyId',
          'cancellation_policy_id',
        ]),
      ),
      billingPolicyId: _toInt(
        _pick(m, const <String>['billingPolicyId', 'billing_policy_id']),
      ),
      bookingNumber: _toStringValue(
        _pick(m, const <String>['bookingNumber', 'booking_number']),
      ),
      status: _toStringValue(_pick(m, const <String>['status'])),
      propertyType: _toStringValue(
        _pick(m, const <String>['propertyType', 'property_type']),
      ),
      locationName: _toStringValue(
        _pick(m, const <String>['locationName', 'location_name']),
      ),
      estimatedSqm: _toStringValue(
        _pick(m, const <String>['estimatedSqm', 'estimated_sqm']),
      ),
      scheduledDate: _toStringValue(
        _pick(m, const <String>['scheduledDate', 'scheduled_date']),
      ),
      scheduledTime: _toStringValue(
        _pick(m, const <String>['scheduledTime', 'scheduled_time']),
      ),
      createdAt: _toStringValue(
        _pick(m, const <String>['createdAt', 'created_at']),
      ),
      updatedAt: _toStringValue(
        _pick(m, const <String>['updatedAt', 'updated_at']),
      ),
      numberOfRooms: _toInt(
        _pick(m, const <String>['numberOfRooms', 'number_of_rooms']),
      ),
      numberOfKitchens: _toInt(
        _pick(m, const <String>['numberOfKitchens', 'number_of_kitchens']),
      ),
      estimatedHours: _toDouble(
        _pick(m, const <String>['estimatedHours', 'estimated_hours']),
      ),
      totalHours: _toDouble(
        _pick(m, const <String>['totalHours', 'total_hours']),
      ),
      basePrice: _toDouble(_pick(m, const <String>['basePrice', 'base_price'])),
      addonsTotal: _toDouble(
        _pick(m, const <String>['addonsTotal', 'addons_total']),
      ),
      travelFee: _toDouble(_pick(m, const <String>['travelFee', 'travel_fee'])),
      cancellationFee: _toDouble(
        _pick(m, const <String>['cancellationFee', 'cancellation_fee']),
      ),
      totalPrice: _toDouble(
        _pick(m, const <String>['totalPrice', 'total_price']),
      ),
      addressLatitude: _toDouble(
        _pick(m, const <String>[
          'addressLatitude',
          'address_latitude',
          'latitude',
        ]),
      ),
      addressLongitude: _toDouble(
        _pick(m, const <String>[
          'addressLongitude',
          'address_longitude',
          'longitude',
        ]),
      ),
      termsAccepted: _toBool(
        _pick(m, const <String>['termsAccepted', 'terms_accepted']),
      ),
      startedTravelAt: _toStringValue(
        _pick(m, const <String>['startedTravelAt', 'started_travel_at']),
      ),
      arrivedAt: _toStringValue(
        _pick(m, const <String>['arrivedAt', 'arrived_at']),
      ),
      workStartedAt: _toStringValue(
        _pick(m, const <String>['workStartedAt', 'work_started_at']),
      ),
      workFinishedAt: _toStringValue(
        _pick(m, const <String>['workFinishedAt', 'work_finished_at']),
      ),
      customerConfirmedAt: _toStringValue(
        _pick(m, const <String>[
          'customerConfirmedAt',
          'customer_confirmed_at',
        ]),
      ),
      cancelledAt: _toStringValue(
        _pick(m, const <String>['cancelledAt', 'cancelled_at']),
      ),
      cancellationReason: _toStringValue(
        _pick(m, const <String>['cancellationReason', 'cancellation_reason']),
      ),
      customer: m['customer'] == null
          ? null
          : FetchOrderDetailsUsecaseModelDataCustomer.fromJson(
              _toMap(m['customer']),
            ),
      worker: m['worker'] == null
          ? null
          : FetchOrderDetailsUsecaseModelDataWorker.fromJson(
              _toMap(m['worker']),
            ),
      propertyDetails: (m['propertyDetails'] ?? m['property_details']) == null
          ? null
          : FetchOrderDetailsUsecaseModelDataPropertyDetails.fromJson(
              _toMap(m['propertyDetails'] ?? m['property_details']),
            ),
      services: _toMapList(
        m['services'],
      ).map(Service.fromJson).toList(growable: false),
      addons: _toMapList(
        m['addons'],
      ).map(Addon.fromJson).toList(growable: false),
      billingPolicy: (m['billingPolicy'] ?? m['billing_policy']) is Map
          ? FetchOrderDetailsUsecaseModelDataBillingPolicy.fromJson(
              _toMap(m['billingPolicy'] ?? m['billing_policy']),
            )
          : null,
      timeWarnings: _toDynamicList(m['timeWarnings'] ?? m['time_warnings']),
      disputes: _toDynamicList(m['disputes']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'workerId': workerId,
      'preferredWorkerId': preferredWorkerId,
      'cancellationPolicyId': cancellationPolicyId,
      'billingPolicyId': billingPolicyId,
      'bookingNumber': bookingNumber,
      'status': status,
      'propertyType': propertyType,
      'locationName': locationName,
      'estimatedSqm': estimatedSqm,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'numberOfRooms': numberOfRooms,
      'numberOfKitchens': numberOfKitchens,
      'estimatedHours': estimatedHours,
      'totalHours': totalHours,
      'basePrice': basePrice,
      'addonsTotal': addonsTotal,
      'travelFee': travelFee,
      'cancellationFee': cancellationFee,
      'totalPrice': totalPrice,
      'addressLatitude': addressLatitude,
      'addressLongitude': addressLongitude,
      'termsAccepted': termsAccepted,
      'startedTravelAt': startedTravelAt,
      'arrivedAt': arrivedAt,
      'workStartedAt': workStartedAt,
      'workFinishedAt': workFinishedAt,
      'customerConfirmedAt': customerConfirmedAt,
      'cancelledAt': cancelledAt,
      'cancellationReason': cancellationReason,
      'customer': customer?.toJson(),
      'worker': worker?.toJson(),
      'propertyDetails': propertyDetails?.toJson(),
      'services': services?.map((e) => e.toJson()).toList(growable: false),
      'addons': addons?.map((e) => e.toJson()).toList(growable: false),
      'billingPolicy': billingPolicy?.toJson(),
      'timeWarnings': timeWarnings,
      'disputes': disputes,
    };
  }
}

class FetchOrderDetailsUsecaseModelDataBillingPolicy {
  final Map<String, dynamic> raw;

  FetchOrderDetailsUsecaseModelDataBillingPolicy({required this.raw});

  factory FetchOrderDetailsUsecaseModelDataBillingPolicy.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchOrderDetailsUsecaseModelDataBillingPolicy(raw: _toMap(json));
  }

  Map<String, dynamic> toJson() {
    return raw;
  }
}

class FetchOrderDetailsUsecaseModelDataWorker {
  final int? id;
  final String? name;
  final String? phone;
  final double? averageRating;
  final String? avatarUrl;

  FetchOrderDetailsUsecaseModelDataWorker({
    this.id,
    this.name,
    this.phone,
    this.averageRating,
    this.avatarUrl,
  });

  factory FetchOrderDetailsUsecaseModelDataWorker.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchOrderDetailsUsecaseModelDataWorker(
      id: _toInt(_pick(json, const <String>['id'])),
      name: _toStringValue(
        _pick(json, const <String>['name', 'firstName', 'first_name']),
      ),
      phone: _toStringValue(_pick(json, const <String>['phone'])),
      averageRating: _toDouble(
        _pick(json, const <String>['averageRating', 'average_rating']),
      ),
      avatarUrl: _toStringValue(
        _pick(json, const <String>['avatarUrl', 'avatar_url']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'averageRating': averageRating,
      'avatarUrl': avatarUrl,
    };
  }
}

class FetchOrderDetailsUsecaseModelDataCustomer {
  final int? id;
  final String? name;
  final String? phone;
  final String? email;

  FetchOrderDetailsUsecaseModelDataCustomer({
    this.id,
    this.name,
    this.phone,
    this.email,
  });

  factory FetchOrderDetailsUsecaseModelDataCustomer.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchOrderDetailsUsecaseModelDataCustomer(
      id: _toInt(_pick(json, const <String>['id'])),
      name: _toStringValue(_pick(json, const <String>['name'])),
      phone: _toStringValue(_pick(json, const <String>['phone'])),
      email: _toStringValue(_pick(json, const <String>['email'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
    };
  }
}

class FetchOrderDetailsUsecaseModelDataPropertyDetails {
  final String? locationName;
  final String? address;
  final int? bedrooms;
  final int? rooms;
  final int? bathrooms;
  final bool? kitchenIncluded;
  final int? kitchens;
  final String? livingRoomSize;

  FetchOrderDetailsUsecaseModelDataPropertyDetails({
    this.locationName,
    this.address,
    this.bedrooms,
    this.rooms,
    this.bathrooms,
    this.kitchenIncluded,
    this.kitchens,
    this.livingRoomSize,
  });

  factory FetchOrderDetailsUsecaseModelDataPropertyDetails.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchOrderDetailsUsecaseModelDataPropertyDetails(
      locationName: _toStringValue(
        _pick(json, const <String>['locationName', 'location_name']),
      ),
      address: _toStringValue(_pick(json, const <String>['address'])),
      bedrooms: _toInt(_pick(json, const <String>['bedrooms'])),
      rooms: _toInt(_pick(json, const <String>['rooms'])),
      bathrooms: _toInt(_pick(json, const <String>['bathrooms'])),
      kitchenIncluded: _toBool(
        _pick(json, const <String>['kitchenIncluded', 'kitchen_included']),
      ),
      kitchens: _toInt(_pick(json, const <String>['kitchens'])),
      livingRoomSize: _toStringValue(
        _pick(json, const <String>['livingRoomSize', 'living_room_size']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'location_name': locationName,
      'address': address,
      'bedrooms': bedrooms,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'kitchen_included': kitchenIncluded,
      'kitchens': kitchens,
      'living_room_size': livingRoomSize,
    };
  }
}
