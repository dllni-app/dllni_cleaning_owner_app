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

FetchOrderDetailsUsecaseModel fetchOrderDetailsUsecaseModelFromJson(str) => FetchOrderDetailsUsecaseModel.fromJson(str);

String fetchOrderDetailsUsecaseModelToJson(FetchOrderDetailsUsecaseModel data) => json.encode(data.toJson());


FetchOrderDetailsUsecaseModelData fetchOrderDetailsUsecaseModelDataFromJson(str) => FetchOrderDetailsUsecaseModelData.fromJson(str);

String fetchOrderDetailsUsecaseModelDataToJson(FetchOrderDetailsUsecaseModelData data) => json.encode(data.toJson());


FetchOrderDetailsUsecaseModelDataBillingPolicy fetchOrderDetailsUsecaseModelDataBillingPolicyFromJson(str) => FetchOrderDetailsUsecaseModelDataBillingPolicy.fromJson(str);

String fetchOrderDetailsUsecaseModelDataBillingPolicyToJson(FetchOrderDetailsUsecaseModelDataBillingPolicy data) => json.encode(data.toJson());


FetchOrderDetailsUsecaseModelDataWorker fetchOrderDetailsUsecaseModelDataWorkerFromJson(str) => FetchOrderDetailsUsecaseModelDataWorker.fromJson(str);

String fetchOrderDetailsUsecaseModelDataWorkerToJson(FetchOrderDetailsUsecaseModelDataWorker data) => json.encode(data.toJson());


FetchOrderDetailsUsecaseModelDataCustomer fetchOrderDetailsUsecaseModelDataCustomerFromJson(str) => FetchOrderDetailsUsecaseModelDataCustomer.fromJson(str);

String fetchOrderDetailsUsecaseModelDataCustomerToJson(FetchOrderDetailsUsecaseModelDataCustomer data) => json.encode(data.toJson());


class FetchOrderDetailsUsecaseModel {
  FetchOrderDetailsUsecaseModelData? data;

  FetchOrderDetailsUsecaseModel({
    this.data,
  });

  factory FetchOrderDetailsUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchOrderDetailsUsecaseModel(
      data: json['data'] is Map ? FetchOrderDetailsUsecaseModelData.fromJson(Map<String, dynamic>.from(json['data'] as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
    };
  }
}

class FetchOrderDetailsUsecaseModelData {
  int? id;
  String? bookingNumber;
  String? status;
  String? scheduledDate;
  String? scheduledTime;
  FetchOrderDetailsUsecaseModelDataCustomer? customer;
  FetchOrderDetailsUsecaseModelDataWorker? worker;
  List<dynamic>? services;
  List<dynamic>? addons;
  FetchOrderDetailsUsecaseModelDataBillingPolicy? billingPolicy;
  List<dynamic>? timeWarnings;
  List<dynamic>? disputes;
  int? totalPrice;

  FetchOrderDetailsUsecaseModelData({
    this.id,
    this.bookingNumber,
    this.status,
    this.scheduledDate,
    this.scheduledTime,
    this.customer,
    this.worker,
    this.services,
    this.addons,
    this.billingPolicy,
    this.timeWarnings,
    this.disputes,
    this.totalPrice,
  });

  factory FetchOrderDetailsUsecaseModelData.fromJson(Map<String, dynamic> json) {
    return FetchOrderDetailsUsecaseModelData(
      id: _asInt(json['id']),
      bookingNumber: _asString(json['bookingNumber']),
      status: _asString(json['status']),
      scheduledDate: _asString(json['scheduledDate']),
      scheduledTime: _asString(json['scheduledTime']),
      customer: json['customer'] is Map ? FetchOrderDetailsUsecaseModelDataCustomer.fromJson(Map<String, dynamic>.from(json['customer'] as Map)) : null,
      worker: json['worker'] is Map ? FetchOrderDetailsUsecaseModelDataWorker.fromJson(Map<String, dynamic>.from(json['worker'] as Map)) : null,
      services: _asDynamicList(json['services']),
      addons: _asDynamicList(json['addons']),
      billingPolicy: json['billingPolicy'] is Map ? FetchOrderDetailsUsecaseModelDataBillingPolicy.fromJson(Map<String, dynamic>.from(json['billingPolicy'] as Map)) : null,
      timeWarnings: _asDynamicList(json['timeWarnings']),
      disputes: _asDynamicList(json['disputes']),
      totalPrice: _asInt(json['totalPrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingNumber': bookingNumber,
      'status': status,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'customer': customer?.toJson(),
      'worker': worker?.toJson(),
      'services': services,
      'addons': addons,
      'billingPolicy': billingPolicy?.toJson(),
      'timeWarnings': timeWarnings,
      'disputes': disputes,
      'totalPrice': totalPrice,
    };
  }
}

class FetchOrderDetailsUsecaseModelDataBillingPolicy {

  FetchOrderDetailsUsecaseModelDataBillingPolicy();

  factory FetchOrderDetailsUsecaseModelDataBillingPolicy.fromJson(Map<String, dynamic> json) {
    return FetchOrderDetailsUsecaseModelDataBillingPolicy();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}

class FetchOrderDetailsUsecaseModelDataWorker {
  int? id;
  String? name;

  FetchOrderDetailsUsecaseModelDataWorker({
    this.id,
    this.name,
  });

  factory FetchOrderDetailsUsecaseModelDataWorker.fromJson(Map<String, dynamic> json) {
    return FetchOrderDetailsUsecaseModelDataWorker(
      id: _asInt(json['id']),
      name: _asString(json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class FetchOrderDetailsUsecaseModelDataCustomer {
  int? id;
  String? name;
  String? phone;

  FetchOrderDetailsUsecaseModelDataCustomer({
    this.id,
    this.name,
    this.phone,
  });

  factory FetchOrderDetailsUsecaseModelDataCustomer.fromJson(Map<String, dynamic> json) {
    return FetchOrderDetailsUsecaseModelDataCustomer(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      phone: _asString(json['phone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }
}