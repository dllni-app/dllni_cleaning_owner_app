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

FetchExtensionRequestsUsecasModel fetchExtensionRequestsUsecasModelFromJson(str) => FetchExtensionRequestsUsecasModel.fromJson(str);

String fetchExtensionRequestsUsecasModelToJson(FetchExtensionRequestsUsecasModel data) => json.encode(data.toJson());


FetchExtensionRequestsUsecasModelMeta fetchExtensionRequestsUsecasModelMetaFromJson(str) => FetchExtensionRequestsUsecasModelMeta.fromJson(str);

String fetchExtensionRequestsUsecasModelMetaToJson(FetchExtensionRequestsUsecasModelMeta data) => json.encode(data.toJson());


FetchExtensionRequestsUsecasModelLinks fetchExtensionRequestsUsecasModelLinksFromJson(str) => FetchExtensionRequestsUsecasModelLinks.fromJson(str);

String fetchExtensionRequestsUsecasModelLinksToJson(FetchExtensionRequestsUsecasModelLinks data) => json.encode(data.toJson());


FetchExtensionRequestsUsecasModelDataItem fetchExtensionRequestsUsecasModelDataItemFromJson(str) => FetchExtensionRequestsUsecasModelDataItem.fromJson(str);

String fetchExtensionRequestsUsecasModelDataItemToJson(FetchExtensionRequestsUsecasModelDataItem data) => json.encode(data.toJson());


class FetchExtensionRequestsUsecasModel {
  List<FetchExtensionRequestsUsecasModelDataItem>? data;
  FetchExtensionRequestsUsecasModelLinks? links;
  FetchExtensionRequestsUsecasModelMeta? meta;

  FetchExtensionRequestsUsecasModel({
    this.data,
    this.links,
    this.meta,
  });

  factory FetchExtensionRequestsUsecasModel.fromJson(Map<String, dynamic> json) {
    return FetchExtensionRequestsUsecasModel(
      data: json['data'] is List ? (json['data'] as List).whereType<Map>().map((item) => FetchExtensionRequestsUsecasModelDataItem.fromJson(Map<String, dynamic>.from(item))).toList() : null,
      links: json['links'] is Map ? FetchExtensionRequestsUsecasModelLinks.fromJson(Map<String, dynamic>.from(json['links'] as Map)) : null,
      meta: json['meta'] is Map ? FetchExtensionRequestsUsecasModelMeta.fromJson(Map<String, dynamic>.from(json['meta'] as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.map((item) => item.toJson()).toList(),
      'links': links?.toJson(),
      'meta': meta?.toJson(),
    };
  }
}

class FetchExtensionRequestsUsecasModelMeta {
  int? currentPage;
  int? perPage;
  int? total;

  FetchExtensionRequestsUsecasModelMeta({
    this.currentPage,
    this.perPage,
    this.total,
  });

  factory FetchExtensionRequestsUsecasModelMeta.fromJson(Map<String, dynamic> json) {
    return FetchExtensionRequestsUsecasModelMeta(
      currentPage: _asInt(json['current_page']),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      'total': total,
    };
  }
}

class FetchExtensionRequestsUsecasModelLinks {
  String? first;
  String? last;
  dynamic prev;
  dynamic next;

  FetchExtensionRequestsUsecasModelLinks({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory FetchExtensionRequestsUsecasModelLinks.fromJson(Map<String, dynamic> json) {
    return FetchExtensionRequestsUsecasModelLinks(
      first: _asString(json['first']),
      last: _asString(json['last']),
      prev: _asDynamic(json['prev']),
      next: _asDynamic(json['next']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first': first,
      'last': last,
      'prev': prev,
      'next': next,
    };
  }
}

class FetchExtensionRequestsUsecasModelDataItem {
  int? id;
  int? bookingId;
  String? bookingType;
  int? requestedMinutes;
  dynamic responseStatus;

  FetchExtensionRequestsUsecasModelDataItem({
    this.id,
    this.bookingId,
    this.bookingType,
    this.requestedMinutes,
    this.responseStatus,
  });

  factory FetchExtensionRequestsUsecasModelDataItem.fromJson(Map<String, dynamic> json) {
    return FetchExtensionRequestsUsecasModelDataItem(
      id: _asInt(json['id']),
      bookingId: _asInt(json['bookingId']),
      bookingType: _asString(json['bookingType']),
      requestedMinutes: _asInt(json['requestedMinutes']),
      responseStatus: _asDynamic(json['responseStatus']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingType': bookingType,
      'requestedMinutes': requestedMinutes,
      'responseStatus': responseStatus,
    };
  }
}