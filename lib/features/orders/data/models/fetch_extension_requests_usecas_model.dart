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

class FetchExtensionRequestsUsecasModelDataItemBooking {
  int? id;
  String? status;

  FetchExtensionRequestsUsecasModelDataItemBooking({this.id, this.status});

  factory FetchExtensionRequestsUsecasModelDataItemBooking.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchExtensionRequestsUsecasModelDataItemBooking(
      id: _asInt(json['id']),
      status: _asString(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'status': status};
}

class FetchExtensionRequestsUsecasModelDataItem {
  int? id;
  int? bookingId;
  String? bookingType;
  int? requestedMinutes;
  int? additionalMinutes;
  String? customerResponse;
  String? workerResponse;
  String? workerRejectMessage;
  String? workerRespondedAt;
  dynamic responseStatus;
  FetchExtensionRequestsUsecasModelDataItemBooking? booking;

  FetchExtensionRequestsUsecasModelDataItem({
    this.id,
    this.bookingId,
    this.bookingType,
    this.requestedMinutes,
    this.additionalMinutes,
    this.customerResponse,
    this.workerResponse,
    this.workerRejectMessage,
    this.workerRespondedAt,
    this.responseStatus,
    this.booking,
  });

  /// Contract field `additionalMinutes` with legacy `requestedMinutes` fallback.
  int? get resolvedAdditionalMinutes =>
      additionalMinutes ?? requestedMinutes;

  bool get isPendingWorkerResponse {
    final status = responseStatus?.toString().trim().toLowerCase();
    if (status == 'accepted' ||
        status == 'rejected' ||
        status == 'resolved' ||
        status == 'closed') {
      return false;
    }
    if (status == 'pending' ||
        status == 'awaiting_worker' ||
        status == 'awaiting_worker_response') {
      return true;
    }

    final workerAnswer = workerResponse?.trim().toLowerCase();
    if (workerAnswer == 'accept' ||
        workerAnswer == 'accepted' ||
        workerAnswer == 'reject' ||
        workerAnswer == 'rejected' ||
        workerAnswer == 'commit_current_time') {
      return false;
    }

    if (workerRespondedAt != null && workerRespondedAt!.trim().isNotEmpty) {
      return false;
    }

    final customerAnswer = customerResponse?.trim().toLowerCase();
    if (customerAnswer == 'extend_time') {
      return workerAnswer == null || workerAnswer.isEmpty;
    }

    return workerAnswer == null || workerAnswer.isEmpty;
  }

  factory FetchExtensionRequestsUsecasModelDataItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchExtensionRequestsUsecasModelDataItem(
      id: _asInt(json['id']),
      bookingId: _asInt(json['bookingId'] ?? json['booking_id']),
      bookingType: _asString(json['bookingType'] ?? json['booking_type']),
      requestedMinutes: _asInt(json['requestedMinutes']),
      additionalMinutes: _asInt(
        json['additionalMinutes'] ?? json['additional_minutes'],
      ),
      customerResponse: _asString(
        json['customerResponse'] ?? json['customer_response'],
      ),
      workerResponse: _asString(
        json['workerResponse'] ?? json['worker_response'],
      ),
      workerRejectMessage: _asString(
        json['workerRejectMessage'] ?? json['worker_reject_message'],
      ),
      workerRespondedAt: _asString(
        json['workerRespondedAt'] ?? json['worker_responded_at'],
      ),
      responseStatus: _asString(json['status']),
      booking: json['booking'] is Map
          ? FetchExtensionRequestsUsecasModelDataItemBooking.fromJson(
              Map<String, dynamic>.from(json['booking'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingType': bookingType,
      'requestedMinutes': requestedMinutes,
      'additionalMinutes': additionalMinutes,
      'customerResponse': customerResponse,
      'workerResponse': workerResponse,
      'workerRejectMessage': workerRejectMessage,
      'workerRespondedAt': workerRespondedAt,
      'responseStatus': responseStatus,
      'booking': booking?.toJson(),
    };
  }
}