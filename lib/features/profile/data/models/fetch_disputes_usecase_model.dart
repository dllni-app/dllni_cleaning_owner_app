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

FetchDisputesUsecaseModel fetchDisputesUsecaseModelFromJson(str) => FetchDisputesUsecaseModel.fromJson(str);

String fetchDisputesUsecaseModelToJson(FetchDisputesUsecaseModel data) => json.encode(data.toJson());

class FetchDisputesUsecaseModel {
  List<FetchDisputesUsecaseModelDataItem>? data;
  FetchDisputesUsecaseModelLinks? links;
  FetchDisputesUsecaseModelMeta? meta;

  FetchDisputesUsecaseModel({this.data, this.links, this.meta});

  factory FetchDisputesUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchDisputesUsecaseModel(
      data: json['data'] is List
          ? (json['data'] as List)
                .whereType<Map>()
                .map((item) => FetchDisputesUsecaseModelDataItem.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : null,
      links: json['links'] is Map ? FetchDisputesUsecaseModelLinks.fromJson(Map<String, dynamic>.from(json['links'])) : null,
      meta: json['meta'] is Map ? FetchDisputesUsecaseModelMeta.fromJson(Map<String, dynamic>.from(json['meta'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {'data': data?.map((e) => e.toJson()).toList(), 'links': links?.toJson(), 'meta': meta?.toJson()};
}

class FetchDisputesUsecaseModelDataItem {
  int? id;
  int? bookingId;
  String? bookingType;
  String? ticketNumber;
  String? status;
  String? category;
  String? resolution;
  Booking? booking;
  String? createdAt;
  String? updatedAt;

  FetchDisputesUsecaseModelDataItem({
    this.id,
    this.bookingId,
    this.bookingType,
    this.ticketNumber,
    this.status,
    this.category,
    this.resolution,
    this.booking,
    this.createdAt,
    this.updatedAt,
  });

  factory FetchDisputesUsecaseModelDataItem.fromJson(Map<String, dynamic> json) {
    return FetchDisputesUsecaseModelDataItem(
      id: _asInt(json['id']),
      bookingId: _asInt(json['bookingId']),
      bookingType: _asString(json['bookingType']),
      ticketNumber: _asString(json['ticketNumber']),
      status: _asString(json['status']),
      category: _asString(json['category']),
      resolution: _asString(json['resolution']),
      booking: json['booking'] is Map ? Booking.fromJson(Map<String, dynamic>.from(json['booking'])) : null,
      createdAt: _asString(json['createdAt']),
      updatedAt: _asString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'bookingType': bookingType,
    'ticketNumber': ticketNumber,
    'status': status,
    'category': category,
    'resolution': resolution,
    'booking': booking?.toJson(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class Booking {
  int? id;
  String? bookingNumber;
  String? status;
  String? propertyType;
  String? scheduledDate;
  String? scheduledTime;
  String? totalPrice;

  Booking({this.id, this.bookingNumber, this.status, this.propertyType, this.scheduledDate, this.scheduledTime, this.totalPrice});

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: _asInt(json['id']),
      bookingNumber: _asString(json['booking_number']),
      status: _asString(json['status']),
      propertyType: _asString(json['property_type']),
      scheduledDate: _asString(json['scheduled_date']),
      scheduledTime: _asString(json['scheduled_time']),
      totalPrice: _asString(json['total_price']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_number': bookingNumber,
    'status': status,
    'property_type': propertyType,
    'scheduled_date': scheduledDate,
    'scheduled_time': scheduledTime,
    'total_price': totalPrice,
  };
}

class FetchDisputesUsecaseModelMeta {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;

  FetchDisputesUsecaseModelMeta({this.currentPage, this.lastPage, this.perPage, this.total});

  factory FetchDisputesUsecaseModelMeta.fromJson(Map<String, dynamic> json) {
    return FetchDisputesUsecaseModelMeta(
      currentPage: _asInt(json['current_page']),
      lastPage: _asInt(json['last_page']),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {'current_page': currentPage, 'last_page': lastPage, 'per_page': perPage, 'total': total};
}

class FetchDisputesUsecaseModelLinks {
  String? first;
  String? last;
  dynamic prev;
  dynamic next;

  FetchDisputesUsecaseModelLinks({this.first, this.last, this.prev, this.next});

  factory FetchDisputesUsecaseModelLinks.fromJson(Map<String, dynamic> json) {
    return FetchDisputesUsecaseModelLinks(first: _asString(json['first']), last: _asString(json['last']), prev: json['prev'], next: json['next']);
  }

  Map<String, dynamic> toJson() => {'first': first, 'last': last, 'prev': prev, 'next': next};
}
