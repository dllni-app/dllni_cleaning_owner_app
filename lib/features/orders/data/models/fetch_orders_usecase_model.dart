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

FetchOrdersUsecaseModel fetchOrdersUsecaseModelFromJson(dynamic json) => FetchOrdersUsecaseModel.fromJson(_toMap(json));

String fetchOrdersUsecaseModelToJson(FetchOrdersUsecaseModel data) => jsonEncode(data.toJson());

FetchOrdersUsecaseModelMeta fetchOrdersUsecaseModelMetaFromJson(dynamic json) => FetchOrdersUsecaseModelMeta.fromJson(_toMap(json));

String fetchOrdersUsecaseModelMetaToJson(FetchOrdersUsecaseModelMeta data) => jsonEncode(data.toJson());

FetchOrdersUsecaseModelLinks fetchOrdersUsecaseModelLinksFromJson(dynamic json) => FetchOrdersUsecaseModelLinks.fromJson(_toMap(json));

String fetchOrdersUsecaseModelLinksToJson(FetchOrdersUsecaseModelLinks data) => jsonEncode(data.toJson());

FetchOrdersUsecaseModelDataItem fetchOrdersUsecaseModelDataItemFromJson(dynamic json) => FetchOrdersUsecaseModelDataItem.fromJson(_toMap(json));

String fetchOrdersUsecaseModelDataItemToJson(FetchOrdersUsecaseModelDataItem data) => jsonEncode(data.toJson());

FetchOrdersUsecaseModelDataItemCustomer fetchOrdersUsecaseModelDataItemCustomerFromJson(dynamic json) => FetchOrdersUsecaseModelDataItemCustomer.fromJson(_toMap(json));

String fetchOrdersUsecaseModelDataItemCustomerToJson(FetchOrdersUsecaseModelDataItemCustomer data) => jsonEncode(data.toJson());

class FetchOrdersUsecaseModel {
  final List<FetchOrdersUsecaseModelDataItem>? data;
  final FetchOrdersUsecaseModelLinks? links;
  final FetchOrdersUsecaseModelMeta? meta;

  FetchOrdersUsecaseModel({this.data, this.links, this.meta});

  factory FetchOrdersUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModel(
      data: _toMapList(json['data']).map(FetchOrdersUsecaseModelDataItem.fromJson).toList(growable: false),
      links: json['links'] == null ? null : FetchOrdersUsecaseModelLinks.fromJson(_toMap(json['links'])),
      meta: json['meta'] == null ? null : FetchOrdersUsecaseModelMeta.fromJson(_toMap(json['meta'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'data': data?.map((item) => item.toJson()).toList(growable: false), 'links': links?.toJson(), 'meta': meta?.toJson()};
  }
}

class FetchOrdersUsecaseModelMeta {
  final int? currentPage;
  final int? from;
  final int? lastPage;
  final String? path;
  final int? perPage;
  final int? to;
  final int? total;

  FetchOrdersUsecaseModelMeta({this.currentPage, this.from, this.lastPage, this.path, this.perPage, this.to, this.total});

  factory FetchOrdersUsecaseModelMeta.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModelMeta(
      currentPage: _toInt(_pick(json, const <String>['currentPage', 'current_page'])),
      from: _toInt(_pick(json, const <String>['from'])),
      lastPage: _toInt(_pick(json, const <String>['lastPage', 'last_page'])),
      path: _toStringValue(_pick(json, const <String>['path'])),
      perPage: _toInt(_pick(json, const <String>['perPage', 'per_page'])),
      to: _toInt(_pick(json, const <String>['to'])),
      total: _toInt(_pick(json, const <String>['total'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'current_page': currentPage, 'from': from, 'last_page': lastPage, 'path': path, 'per_page': perPage, 'to': to, 'total': total};
  }
}

class FetchOrdersUsecaseModelLinks {
  final String? first;
  final String? last;
  final dynamic prev;
  final dynamic next;

  FetchOrdersUsecaseModelLinks({this.first, this.last, this.prev, this.next});

  factory FetchOrdersUsecaseModelLinks.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModelLinks(
      first: _toStringValue(_pick(json, const <String>['first'])),
      last: _toStringValue(_pick(json, const <String>['last'])),
      prev: _pick(json, const <String>['prev']),
      next: _pick(json, const <String>['next']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'first': first, 'last': last, 'prev': prev, 'next': next};
  }
}

class FetchOrdersUsecaseModelDataItem {
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

  final FetchOrdersUsecaseModelDataItemCustomer? customer;
  final WorkerData? worker;
  final PropertyDetailsData? propertyDetails;

  final List<Service>? services;
  final List<Addon>? addons;
  final Map<String, dynamic>? billingPolicy;
  final List<dynamic>? timeWarnings;
  final List<dynamic>? disputes;

  FetchOrdersUsecaseModelDataItem({
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

  factory FetchOrdersUsecaseModelDataItem.fromJson(Map<String, dynamic> json) {
    final m = _withTracking(json);
    return FetchOrdersUsecaseModelDataItem(
      id: _toInt(_pick(m, const <String>['id'])),
      customerId: _toInt(_pick(m, const <String>['customerId', 'customer_id'])),
      workerId: _toInt(_pick(m, const <String>['workerId', 'worker_id'])),
      preferredWorkerId: _toInt(_pick(m, const <String>['preferredWorkerId', 'preferred_worker_id'])),
      cancellationPolicyId: _toInt(_pick(m, const <String>['cancellationPolicyId', 'cancellation_policy_id'])),
      billingPolicyId: _toInt(_pick(m, const <String>['billingPolicyId', 'billing_policy_id'])),
      bookingNumber: _toStringValue(_pick(m, const <String>['bookingNumber', 'booking_number'])),
      status: _toStringValue(_pick(m, const <String>['status'])),
      propertyType: _toStringValue(_pick(m, const <String>['propertyType', 'property_type'])),
      locationName: _toStringValue(_pick(m, const <String>['locationName', 'location_name'])),
      estimatedSqm: _toStringValue(_pick(m, const <String>['estimatedSqm', 'estimated_sqm'])),
      scheduledDate: _toStringValue(_pick(m, const <String>['scheduledDate', 'scheduled_date'])),
      scheduledTime: _toStringValue(_pick(m, const <String>['scheduledTime', 'scheduled_time'])),
      createdAt: _toStringValue(_pick(m, const <String>['createdAt', 'created_at'])),
      updatedAt: _toStringValue(_pick(m, const <String>['updatedAt', 'updated_at'])),
      numberOfRooms: _toInt(_pick(m, const <String>['numberOfRooms', 'number_of_rooms'])),
      numberOfKitchens: _toInt(_pick(m, const <String>['numberOfKitchens', 'number_of_kitchens'])),
      estimatedHours: _toDouble(_pick(m, const <String>['estimatedHours', 'estimated_hours'])),
      totalHours: _toDouble(_pick(m, const <String>['totalHours', 'total_hours'])),
      basePrice: _toDouble(_pick(m, const <String>['basePrice', 'base_price'])),
      addonsTotal: _toDouble(_pick(m, const <String>['addonsTotal', 'addons_total'])),
      travelFee: _toDouble(_pick(m, const <String>['travelFee', 'travel_fee'])),
      cancellationFee: _toDouble(_pick(m, const <String>['cancellationFee', 'cancellation_fee'])),
      totalPrice: _toDouble(_pick(m, const <String>['totalPrice', 'total_price'])),
      addressLatitude: _toDouble(_pick(m, const <String>['addressLatitude', 'address_latitude', 'latitude'])),
      addressLongitude: _toDouble(_pick(m, const <String>['addressLongitude', 'address_longitude', 'longitude'])),
      termsAccepted: _toBool(_pick(m, const <String>['termsAccepted', 'terms_accepted'])),
      startedTravelAt: _toStringValue(_pick(m, const <String>['startedTravelAt', 'started_travel_at'])),
      arrivedAt: _toStringValue(_pick(m, const <String>['arrivedAt', 'arrived_at'])),
      workStartedAt: _toStringValue(_pick(m, const <String>['workStartedAt', 'work_started_at'])),
      workFinishedAt: _toStringValue(_pick(m, const <String>['workFinishedAt', 'work_finished_at'])),
      customerConfirmedAt: _toStringValue(_pick(m, const <String>['customerConfirmedAt', 'customer_confirmed_at'])),
      cancelledAt: _toStringValue(_pick(m, const <String>['cancelledAt', 'cancelled_at'])),
      cancellationReason: _toStringValue(_pick(m, const <String>['cancellationReason', 'cancellation_reason'])),
      customer: m['customer'] == null ? null : FetchOrdersUsecaseModelDataItemCustomer.fromJson(_toMap(m['customer'])),
      worker: m['worker'] == null ? null : WorkerData.fromJson(_toMap(m['worker'])),
      propertyDetails: (m['propertyDetails'] ?? m['property_details']) == null ? null : PropertyDetailsData.fromJson(_toMap(m['propertyDetails'] ?? m['property_details'])),
      services: _toMapList(m['services']).map(Service.fromJson).toList(growable: false),
      addons: _toMapList(m['addons']).map(Addon.fromJson).toList(growable: false),
      billingPolicy: m['billingPolicy'] is Map ? _toMap(m['billingPolicy']) : (m['billing_policy'] is Map ? _toMap(m['billing_policy']) : null),
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
      'billingPolicy': billingPolicy,
      'timeWarnings': timeWarnings,
      'disputes': disputes,
    };
  }

  FetchOrdersUsecaseModelDataItem withLifecycle({String? status, String? arrivedAt, String? startedTravelAt, String? workStartedAt, String? workFinishedAt, String? customerConfirmedAt}) {
    return FetchOrdersUsecaseModelDataItem(
      id: id,
      customerId: customerId,
      workerId: workerId,
      preferredWorkerId: preferredWorkerId,
      cancellationPolicyId: cancellationPolicyId,
      billingPolicyId: billingPolicyId,
      bookingNumber: bookingNumber,
      status: status ?? this.status,
      propertyType: propertyType,
      locationName: locationName,
      estimatedSqm: estimatedSqm,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      numberOfRooms: numberOfRooms,
      numberOfKitchens: numberOfKitchens,
      estimatedHours: estimatedHours,
      totalHours: totalHours,
      basePrice: basePrice,
      addonsTotal: addonsTotal,
      travelFee: travelFee,
      cancellationFee: cancellationFee,
      totalPrice: totalPrice,
      addressLatitude: addressLatitude,
      addressLongitude: addressLongitude,
      termsAccepted: termsAccepted,
      startedTravelAt: startedTravelAt ?? this.startedTravelAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      workStartedAt: workStartedAt ?? this.workStartedAt,
      workFinishedAt: workFinishedAt ?? this.workFinishedAt,
      customerConfirmedAt: customerConfirmedAt ?? this.customerConfirmedAt,
      cancelledAt: cancelledAt,
      cancellationReason: cancellationReason,
      customer: customer,
      worker: worker,
      propertyDetails: propertyDetails,
      services: services,
      addons: addons,
      billingPolicy: billingPolicy,
      timeWarnings: timeWarnings,
      disputes: disputes,
    );
  }
}

class WorkerData {
  final int? id;
  final String? firstName;
  final String? phone;
  final double? averageRating;
  final String? avatarUrl;

  WorkerData({this.id, this.firstName, this.phone, this.averageRating, this.avatarUrl});

  factory WorkerData.fromJson(Map<String, dynamic> json) {
    return WorkerData(
      id: _toInt(_pick(json, const <String>['id'])),
      firstName: _toStringValue(_pick(json, const <String>['firstName', 'first_name', 'name'])),
      phone: _toStringValue(_pick(json, const <String>['phone'])),
      averageRating: _toDouble(_pick(json, const <String>['averageRating', 'average_rating'])),
      avatarUrl: _toStringValue(_pick(json, const <String>['avatarUrl', 'avatar_url'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'firstName': firstName, 'phone': phone, 'averageRating': averageRating, 'avatarUrl': avatarUrl};
  }
}

class PropertyDetailsData {
  final String? locationName;
  final String? address;
  final String? kitchen;
  final int? rooms;
  final int? bedRooms;
  final int? bathrooms;
  final bool? kitchenIncluded;
  final int? kitchens;
  final String? livingRoomSize;

  PropertyDetailsData({this.locationName, this.address, this.rooms,this.kitchen, this.bedRooms, this.bathrooms, this.kitchenIncluded, this.kitchens, this.livingRoomSize});

  factory PropertyDetailsData.fromJson(Map<String, dynamic> json) {
    return PropertyDetailsData(
      locationName: _toStringValue(_pick(json, const <String>['locationName', 'location_name'])),
      address: _toStringValue(_pick(json, const <String>['address'])),
      rooms: _toInt(_pick(json, const <String>['rooms'])),
      kitchen: _toStringValue(_pick(json, const <String>['kitchen'])),
      bedRooms: _toInt(_pick(json, const <String>['bedRooms', 'bedrooms'])),
      bathrooms: _toInt(_pick(json, const <String>['bathrooms'])),
      kitchenIncluded: _toBool(_pick(json, const <String>['kitchenIncluded', 'kitchen_included'])),
      kitchens: _toInt(_pick(json, const <String>['kitchens'])),
      livingRoomSize: _toStringValue(_pick(json, const <String>['livingRoomSize', 'living_room_size'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'location_name': locationName,
      'address': address,
      'rooms': rooms,
      'bedrooms': bedRooms,
      'bathrooms': bathrooms,
      'kitchen_included': kitchenIncluded,
      'kitchens': kitchens,
      'living_room_size': livingRoomSize,
    };
  }
}

class FetchOrdersUsecaseModelDataItemCustomer {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;

  FetchOrdersUsecaseModelDataItemCustomer({this.id, this.name, this.email, this.phone});

  factory FetchOrdersUsecaseModelDataItemCustomer.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModelDataItemCustomer(
      id: _toInt(_pick(json, const <String>['id'])),
      name: _toStringValue(_pick(json, const <String>['name'])),
      email: _toStringValue(_pick(json, const <String>['email'])),
      phone: _toStringValue(_pick(json, const <String>['phone'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'email': email, 'phone': phone};
  }
}
