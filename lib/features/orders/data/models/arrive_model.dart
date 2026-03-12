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

ArriveModel arriveModelFromJson(str) => ArriveModel.fromJson(str);

String arriveModelToJson(ArriveModel data) => json.encode(data.toJson());

ArriveModelData arriveModelDataFromJson(str) => ArriveModelData.fromJson(str);

String arriveModelDataToJson(ArriveModelData data) => json.encode(data.toJson());

class ArriveModel {
  ArriveModelData? data;

  ArriveModel({this.data});

  factory ArriveModel.fromJson(Map<String, dynamic> json) {
    return ArriveModel(data: json['data'] is Map ? ArriveModelData.fromJson(Map<String, dynamic>.from(json['data'])) : null);
  }

  Map<String, dynamic> toJson() {
    return {"data": data?.toJson()};
  }
}

class ArriveModelData {
  int? id;
  int? customerId;
  int? workerId;
  int? preferredWorkerId;
  int? cancellationPolicyId;
  int? billingPolicyId;

  String? bookingNumber;
  String? status;
  String? propertyType;

  PropertyDetails? propertyDetails;

  double? addressLatitude;
  double? addressLongitude;

  String? locationName;

  int? numberOfRooms;

  double? estimatedSqm;
  double? estimatedHours;
  double? totalHours;

  String? scheduledDate;
  String? scheduledTime;

  num? basePrice;
  num? addonsTotal;
  num? travelFee;
  num? cancellationFee;
  num? totalPrice;

  bool? termsAccepted;

  String? workStartedAt;
  String? workFinishedAt;
  String? startedTravelAt;
  String? arrivedAt;
  String? customerConfirmedAt;
  String? cancelledAt;
  String? cancellationReason;

  Customer? customer;
  Worker? worker;

  List<Service>? services;
  List<Addon>? addons;

  BillingPolicy? billingPolicy;

  List<dynamic>? timeWarnings;
  List<dynamic>? disputes;

  String? createdAt;
  String? updatedAt;

  ArriveModelData({
    this.id,
    this.customerId,
    this.workerId,
    this.preferredWorkerId,
    this.cancellationPolicyId,
    this.billingPolicyId,
    this.bookingNumber,
    this.status,
    this.propertyType,
    this.propertyDetails,
    this.addressLatitude,
    this.addressLongitude,
    this.locationName,
    this.numberOfRooms,
    this.estimatedSqm,
    this.estimatedHours,
    this.totalHours,
    this.scheduledDate,
    this.scheduledTime,
    this.basePrice,
    this.addonsTotal,
    this.travelFee,
    this.cancellationFee,
    this.totalPrice,
    this.termsAccepted,
    this.workStartedAt,
    this.workFinishedAt,
    this.startedTravelAt,
    this.arrivedAt,
    this.customerConfirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.customer,
    this.worker,
    this.services,
    this.addons,
    this.billingPolicy,
    this.timeWarnings,
    this.disputes,
    this.createdAt,
    this.updatedAt,
  });

  factory ArriveModelData.fromJson(Map<String, dynamic> json) {
    return ArriveModelData(
      id: _asInt(json['id']),
      customerId: _asInt(json['customerId']),
      workerId: _asInt(json['workerId']),
      preferredWorkerId: _asInt(json['preferredWorkerId']),
      cancellationPolicyId: _asInt(json['cancellationPolicyId']),
      billingPolicyId: _asInt(json['billingPolicyId']),
      bookingNumber: _asString(json['bookingNumber']),
      status: _asString(json['status']),
      propertyType: _asString(json['propertyType']),
      propertyDetails: json['propertyDetails'] is Map ? PropertyDetails.fromJson(json['propertyDetails']) : null,
      addressLatitude: _asDouble(json['addressLatitude']),
      addressLongitude: _asDouble(json['addressLongitude']),
      locationName: _asString(json['locationName']),
      numberOfRooms: _asInt(json['numberOfRooms']),
      estimatedSqm: _asDouble(json['estimatedSqm']),
      estimatedHours: _asDouble(json['estimatedHours']),
      totalHours: _asDouble(json['totalHours']),
      scheduledDate: _asString(json['scheduledDate']),
      scheduledTime: _asString(json['scheduledTime']),
      basePrice: _asNum(json['basePrice']),
      addonsTotal: _asNum(json['addonsTotal']),
      travelFee: _asNum(json['travelFee']),
      cancellationFee: _asNum(json['cancellationFee']),
      totalPrice: _asNum(json['totalPrice']),
      termsAccepted: _asBool(json['termsAccepted']),
      workStartedAt: _asString(json['workStartedAt']),
      workFinishedAt: _asString(json['workFinishedAt']),
      startedTravelAt: _asString(json['startedTravelAt']),
      arrivedAt: _asString(json['arrivedAt']),
      customerConfirmedAt: _asString(json['customerConfirmedAt']),
      cancelledAt: _asString(json['cancelledAt']),
      cancellationReason: _asString(json['cancellationReason']),
      customer: json['customer'] is Map ? Customer.fromJson(json['customer']) : null,
      worker: json['worker'] is Map ? Worker.fromJson(json['worker']) : null,
      services: json['services'] is List ? (json['services'] as List).map((e) => Service.fromJson(Map<String, dynamic>.from(e))).toList() : null,

      addons: json['addons'] is List ? (json['addons'] as List).map((e) => Addon.fromJson(Map<String, dynamic>.from(e))).toList() : null,
      billingPolicy: json['billingPolicy'] is Map ? BillingPolicy.fromJson(json['billingPolicy']) : null,
      timeWarnings: json['timeWarnings'],
      disputes: json['disputes'],
      createdAt: _asString(json['createdAt']),
      updatedAt: _asString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "customerId": customerId,
      "workerId": workerId,
      "preferredWorkerId": preferredWorkerId,
      "cancellationPolicyId": cancellationPolicyId,
      "billingPolicyId": billingPolicyId,
      "bookingNumber": bookingNumber,
      "status": status,
      "propertyType": propertyType,
      "propertyDetails": propertyDetails?.toJson(),
      "addressLatitude": addressLatitude,
      "addressLongitude": addressLongitude,
      "locationName": locationName,
      "numberOfRooms": numberOfRooms,
      "estimatedSqm": estimatedSqm,
      "estimatedHours": estimatedHours,
      "totalHours": totalHours,
      "scheduledDate": scheduledDate,
      "scheduledTime": scheduledTime,
      "basePrice": basePrice,
      "addonsTotal": addonsTotal,
      "travelFee": travelFee,
      "cancellationFee": cancellationFee,
      "totalPrice": totalPrice,
      "termsAccepted": termsAccepted,
      "workStartedAt": workStartedAt,
      "workFinishedAt": workFinishedAt,
      "startedTravelAt": startedTravelAt,
      "arrivedAt": arrivedAt,
      "customerConfirmedAt": customerConfirmedAt,
      "cancelledAt": cancelledAt,
      "cancellationReason": cancellationReason,
      "customer": customer?.toJson(),
      "worker": worker?.toJson(),
      "services": services?.map((e) => e.toJson()).toList(),
      "addons": addons?.map((e) => e.toJson()).toList(),
      "billingPolicy": billingPolicy?.toJson(),
      "timeWarnings": timeWarnings,
      "disputes": disputes,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}

class PropertyDetails {
  String? locationName;
  String? address;
  int? bedrooms;
  int? rooms;
  int? bathrooms;
  bool? kitchenIncluded;

  PropertyDetails({this.locationName, this.address, this.bedrooms, this.rooms, this.bathrooms, this.kitchenIncluded});

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      locationName: _asString(json['location_name']),
      address: _asString(json['address']),
      bedrooms: _asInt(json['bedrooms']),
      rooms: _asInt(json['rooms']),
      bathrooms: _asInt(json['bathrooms']),
      kitchenIncluded: _asBool(json['kitchen_included']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "location_name": locationName,
      "address": address,
      "bedrooms": bedrooms,
      "rooms": rooms,
      "bathrooms": bathrooms,
      "kitchen_included": kitchenIncluded,
    };
  }
}

class Customer {
  int? id;
  String? name;
  String? email;
  String? phone;

  Customer({this.id, this.name, this.email, this.phone});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(id: _asInt(json['id']), name: _asString(json['name']), email: _asString(json['email']), phone: _asString(json['phone']));
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "email": email, "phone": phone};
  }
}

class Worker {
  int? id;
  String? firstName;

  Worker({this.id, this.firstName});

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(id: _asInt(json['id']), firstName: _asString(json['firstName']));
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "firstName": firstName};
  }
}

class BillingPolicy {
  int? id;
  String? name;
  String? billingMode;
  BillingRules? rules;
  bool? isActive;
  bool? isDefault;
  String? createdAt;
  String? updatedAt;

  BillingPolicy({this.id, this.name, this.billingMode, this.rules, this.isActive, this.isDefault, this.createdAt, this.updatedAt});

  factory BillingPolicy.fromJson(Map<String, dynamic> json) {
    return BillingPolicy(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      billingMode: _asString(json['billing_mode']),
      rules: json['rules'] is Map ? BillingRules.fromJson(json['rules']) : null,
      isActive: _asBool(json['is_active']),
      isDefault: _asBool(json['is_default']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "billing_mode": billingMode,
      "rules": rules?.toJson(),
      "is_active": isActive,
      "is_default": isDefault,
      "created_at": createdAt,
      "updated_at": updatedAt,
    };
  }
}

class BillingRules {
  bool? chargeFullBookedHours;
  double? overtimeRate;

  BillingRules({this.chargeFullBookedHours, this.overtimeRate});

  factory BillingRules.fromJson(Map<String, dynamic> json) {
    return BillingRules(chargeFullBookedHours: _asBool(json['charge_full_booked_hours']), overtimeRate: _asDouble(json['overtime_rate']));
  }

  Map<String, dynamic> toJson() {
    return {"charge_full_booked_hours": chargeFullBookedHours, "overtime_rate": overtimeRate};
  }
}

class Service {
  int? id;
  String? name;
  int? quantity;

  Service({this.id, this.name, this.quantity});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(id: _asInt(json['id']), name: _asString(json['name']), quantity: _asInt(json['quantity']));
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "quantity": quantity};
  }
}

class Addon {
  int? id;
  String? name;
  int? quantity;

  Addon({this.id, this.name, this.quantity});

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(id: _asInt(json['id']), name: _asString(json['name']), quantity: _asInt(json['quantity']));
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "quantity": quantity};
  }
}
