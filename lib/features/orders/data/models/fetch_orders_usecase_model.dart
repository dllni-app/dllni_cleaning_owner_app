import 'dart:convert';

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

List<dynamic>? _asDynamicList(dynamic value) {
  if (value is! List) return null;
  return value.map(_asDynamic).toList();
}

dynamic _asDynamic(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map(_asDynamic).toList();
  }
  if (value is Map) {
    final map = <String, dynamic>{};
    value.forEach((key, nestedValue) {
      map['$key'] = _asDynamic(nestedValue);
    });
    return map;
  }
  if (value is String || value is num || value is bool) {
    return value;
  }
  return value.toString();
}

FetchOrdersUsecaseModel fetchOrdersUsecaseModelFromJson(str) => FetchOrdersUsecaseModel.fromJson(str);

String fetchOrdersUsecaseModelToJson(FetchOrdersUsecaseModel data) => json.encode(data.toJson());

FetchOrdersUsecaseModelMeta fetchOrdersUsecaseModelMetaFromJson(str) => FetchOrdersUsecaseModelMeta.fromJson(str);

String fetchOrdersUsecaseModelMetaToJson(FetchOrdersUsecaseModelMeta data) => json.encode(data.toJson());

FetchOrdersUsecaseModelLinks fetchOrdersUsecaseModelLinksFromJson(str) => FetchOrdersUsecaseModelLinks.fromJson(str);

String fetchOrdersUsecaseModelLinksToJson(FetchOrdersUsecaseModelLinks data) => json.encode(data.toJson());

FetchOrdersUsecaseModelDataItem fetchOrdersUsecaseModelDataItemFromJson(str) => FetchOrdersUsecaseModelDataItem.fromJson(str);

String fetchOrdersUsecaseModelDataItemToJson(FetchOrdersUsecaseModelDataItem data) => json.encode(data.toJson());

FetchOrdersUsecaseModelDataItemCustomer fetchOrdersUsecaseModelDataItemCustomerFromJson(str) => FetchOrdersUsecaseModelDataItemCustomer.fromJson(str);

String fetchOrdersUsecaseModelDataItemCustomerToJson(FetchOrdersUsecaseModelDataItemCustomer data) => json.encode(data.toJson());

class FetchOrdersUsecaseModel {
  List<FetchOrdersUsecaseModelDataItem>? data;
  FetchOrdersUsecaseModelLinks? links;
  FetchOrdersUsecaseModelMeta? meta;

  FetchOrdersUsecaseModel({this.data, this.links, this.meta});

  factory FetchOrdersUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModel(
      data: json['data'] is List
          ? (json['data'] as List).whereType<Map>().map((item) => FetchOrdersUsecaseModelDataItem.fromJson(Map<String, dynamic>.from(item))).toList()
          : null,
      links: json['links'] is Map ? FetchOrdersUsecaseModelLinks.fromJson(Map<String, dynamic>.from(json['links'] as Map)) : null,
      meta: json['meta'] is Map ? FetchOrdersUsecaseModelMeta.fromJson(Map<String, dynamic>.from(json['meta'] as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data?.map((item) => item.toJson()).toList(), 'links': links?.toJson(), 'meta': meta?.toJson()};
  }
}

class FetchOrdersUsecaseModelMeta {
  int? currentPage;
  int? from;
  int? lastPage;
  String? path;
  int? perPage;
  int? to;
  int? total;

  FetchOrdersUsecaseModelMeta({this.currentPage, this.from, this.lastPage, this.path, this.perPage, this.to, this.total});

  factory FetchOrdersUsecaseModelMeta.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModelMeta(
      currentPage: _asInt(json['current_page']),
      from: _asInt(json['from']),
      lastPage: _asInt(json['last_page']),
      path: _asString(json['path']),
      perPage: _asInt(json['per_page']),
      to: _asInt(json['to']),
      total: _asInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'current_page': currentPage, 'from': from, 'last_page': lastPage, 'path': path, 'per_page': perPage, 'to': to, 'total': total};
  }
}

class FetchOrdersUsecaseModelLinks {
  String? first;
  String? last;
  dynamic prev;
  dynamic next;

  FetchOrdersUsecaseModelLinks({this.first, this.last, this.prev, this.next});

  factory FetchOrdersUsecaseModelLinks.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModelLinks(
      first: _asString(json['first']),
      last: _asString(json['last']),
      prev: _asDynamic(json['prev']),
      next: _asDynamic(json['next']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'first': first, 'last': last, 'prev': prev, 'next': next};
  }
}

class FetchOrdersUsecaseModelDataItem {
  int? id;
  String? bookingNumber;
  String? status;
  String? scheduledDate;
  String? scheduledTime;
  String? locationName;
  int? numberOfRooms;
  int? estimatedHours;
  String? estimatedSqm;
  int? totalHours;
  FetchOrdersUsecaseModelDataItemCustomer? customer;
  String? propertyType;
  PropertyDetailsData? propertyDetails;
  int? totalPrice;
  String? createdAt;
  String? updatedAt;

  int? customerId;
  int? workerId;
  int? preferredWorkerId;
  int? cancellationPolicyId;
  int? billingPolicyId;

  double? basePrice;
  double? addonsTotal;
  double? travelFee;
  double? cancellationFee;

  bool? termsAccepted;

  String? workStartedAt;
  String? workFinishedAt;
  String? startedTravelAt;
  String? customerConfirmedAt;
  String? cancelledAt;
  String? cancellationReason;

  WorkerData? worker;

  FetchOrdersUsecaseModelDataItem({
    this.id,
    this.bookingNumber,
    this.status,
    this.scheduledDate,
    this.scheduledTime,
    this.locationName,
    this.numberOfRooms,
    this.estimatedHours,
    this.totalHours,
    this.customer,
    this.propertyType,
    this.propertyDetails,
    this.totalPrice,
    this.createdAt,
    this.updatedAt,
    this.estimatedSqm,
    this.addonsTotal,
    this.basePrice,
    this.billingPolicyId,
    this.cancellationFee,
    this.cancellationPolicyId,
    this.cancellationReason,
    this.cancelledAt,
    this.customerConfirmedAt,
    this.customerId,
    this.preferredWorkerId,
    this.startedTravelAt,
    this.termsAccepted,
    this.travelFee,
    this.worker,
    this.workerId,
    this.workFinishedAt,
    this.workStartedAt,
  });

  factory FetchOrdersUsecaseModelDataItem.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModelDataItem(
      id: _asInt(json['id']),
      bookingNumber: _asString(json['bookingNumber']),
      status: _asString(json['status']),
      scheduledDate: _asString(json['scheduledDate']),
      estimatedSqm: _asString(json['estimatedSqm']),
      scheduledTime: _asString(json['scheduledTime']),
      locationName: _asString(json['locationName']),
      numberOfRooms: _asInt(json['numberOfRooms']),
      estimatedHours: _asInt(json['estimatedHours']),
      totalHours: _asInt(json['totalHours']),
      customer: json['customer'] is Map ? FetchOrdersUsecaseModelDataItemCustomer.fromJson(Map<String, dynamic>.from(json['customer'] as Map)) : null,
      propertyType: _asString(json['propertyType']),
      propertyDetails: json['propertyDetails'] is Map
          ? PropertyDetailsData.fromJson(Map<String, dynamic>.from(json['propertyDetails'] as Map))
          : null,
      totalPrice: _asInt(json['totalPrice']),
      createdAt: _asString(json['createdAt']),
      updatedAt: _asString(json['updatedAt']),
      customerId: _asInt(json['customerId']),
      workerId: _asInt(json['workerId']),
      preferredWorkerId: _asInt(json['preferredWorkerId']),
      cancellationPolicyId: _asInt(json['cancellationPolicyId']),
      billingPolicyId: _asInt(json['billingPolicyId']),

      basePrice: _asDouble(json['basePrice']),
      addonsTotal: _asDouble(json['addonsTotal']),
      travelFee: _asDouble(json['travelFee']),
      cancellationFee: _asDouble(json['cancellationFee']),

      termsAccepted: _asBool(json['termsAccepted']),

      workStartedAt: _asString(json['workStartedAt']),
      workFinishedAt: _asString(json['workFinishedAt']),
      startedTravelAt: _asString(json['startedTravelAt']),
      customerConfirmedAt: _asString(json['customerConfirmedAt']),
      cancelledAt: _asString(json['cancelledAt']),
      cancellationReason: _asString(json['cancellationReason']),

      worker: json['worker'] is Map ? WorkerData.fromJson(Map<String, dynamic>.from(json['worker'])) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingNumber': bookingNumber,
      'status': status,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'locationName': locationName,
      'numberOfRooms': numberOfRooms,
      'estimatedHours': estimatedHours,
      'totalHours': totalHours,
      'customer': customer?.toJson(),
      'propertyType': propertyType,
      'propertyDetails': propertyDetails,
      'totalPrice': totalPrice,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class WorkerData {
  int? id;
  String? firstName;

  WorkerData({this.id, this.firstName});

  factory WorkerData.fromJson(Map<String, dynamic> json) {
    return WorkerData(id: _asInt(json['id']), firstName: _asString(json['firstName']));
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'firstName': firstName};
  }
}

class PropertyDetailsData {
  String? locationName;
  String? address;
  int? rooms;
  int? bedRooms;
  int? bathrooms;
  bool? kitchen;

  PropertyDetailsData({this.locationName, this.address, this.rooms, this.bedRooms, this.bathrooms, this.kitchen});

  factory PropertyDetailsData.fromJson(Map<String, dynamic> json) {
    return PropertyDetailsData(
      locationName: _asString(json['location_name']),
      address: _asString(json['address']),
      rooms: _asInt(json['rooms']),
      bedRooms: _asInt(json['bedrooms']),
      bathrooms: _asInt(json['bathrooms']),
      kitchen: _asBool(json['kitchen_included']),
    );
  }
}

class FetchOrdersUsecaseModelDataItemCustomer {
  int? id;
  String? name;
  String? email;
  String? phone;

  FetchOrdersUsecaseModelDataItemCustomer({this.id, this.name, this.email, this.phone});

  factory FetchOrdersUsecaseModelDataItemCustomer.fromJson(Map<String, dynamic> json) {
    return FetchOrdersUsecaseModelDataItemCustomer(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'phone': phone};
  }
}
