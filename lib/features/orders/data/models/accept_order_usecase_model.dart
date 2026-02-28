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

AcceptOrderUsecaseModel acceptOrderUsecaseModelFromJson(str) => AcceptOrderUsecaseModel.fromJson(str);

String acceptOrderUsecaseModelToJson(AcceptOrderUsecaseModel data) => json.encode(data.toJson());


AcceptOrderUsecaseModelData acceptOrderUsecaseModelDataFromJson(str) => AcceptOrderUsecaseModelData.fromJson(str);

String acceptOrderUsecaseModelDataToJson(AcceptOrderUsecaseModelData data) => json.encode(data.toJson());


AcceptOrderUsecaseModelDataCustomer acceptOrderUsecaseModelDataCustomerFromJson(str) => AcceptOrderUsecaseModelDataCustomer.fromJson(str);

String acceptOrderUsecaseModelDataCustomerToJson(AcceptOrderUsecaseModelDataCustomer data) => json.encode(data.toJson());


class AcceptOrderUsecaseModel {
  AcceptOrderUsecaseModelData? data;

  AcceptOrderUsecaseModel({
    this.data,
  });

  factory AcceptOrderUsecaseModel.fromJson(Map<String, dynamic> json) {
    return AcceptOrderUsecaseModel(
      data: json['data'] is Map ? AcceptOrderUsecaseModelData.fromJson(Map<String, dynamic>.from(json['data'] as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
    };
  }
}

class AcceptOrderUsecaseModelData {
  int? id;
  String? status;
  String? bookingNumber;
  String? scheduledDate;
  AcceptOrderUsecaseModelDataCustomer? customer;
  int? totalPrice;

  AcceptOrderUsecaseModelData({
    this.id,
    this.status,
    this.bookingNumber,
    this.scheduledDate,
    this.customer,
    this.totalPrice,
  });

  factory AcceptOrderUsecaseModelData.fromJson(Map<String, dynamic> json) {
    return AcceptOrderUsecaseModelData(
      id: _asInt(json['id']),
      status: _asString(json['status']),
      bookingNumber: _asString(json['bookingNumber']),
      scheduledDate: _asString(json['scheduledDate']),
      customer: json['customer'] is Map ? AcceptOrderUsecaseModelDataCustomer.fromJson(Map<String, dynamic>.from(json['customer'] as Map)) : null,
      totalPrice: _asInt(json['totalPrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'bookingNumber': bookingNumber,
      'scheduledDate': scheduledDate,
      'customer': customer?.toJson(),
      'totalPrice': totalPrice,
    };
  }
}

class AcceptOrderUsecaseModelDataCustomer {
  int? id;
  String? name;
  String? phone;

  AcceptOrderUsecaseModelDataCustomer({
    this.id,
    this.name,
    this.phone,
  });

  factory AcceptOrderUsecaseModelDataCustomer.fromJson(Map<String, dynamic> json) {
    return AcceptOrderUsecaseModelDataCustomer(
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