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

FetchHomePageUsecaseModel fetchHomePageUsecaseModelFromJson(str) => FetchHomePageUsecaseModel.fromJson(str);

String fetchHomePageUsecaseModelToJson(FetchHomePageUsecaseModel data) => json.encode(data.toJson());


class FetchHomePageUsecaseModel {
  int? totalBookings;
  int? todayCount;
  int? completedCount;
  int? pendingCount;
  int? inProgressCount;
  int? cancelledCount;
  double? totalEarnings;
  double? todayEarnings;
  int? newOrdersCount;
  int? pendingExtensionRequestsCount;

  FetchHomePageUsecaseModel({
    this.totalBookings,
    this.todayCount,
    this.completedCount,
    this.pendingCount,
    this.inProgressCount,
    this.cancelledCount,
    this.totalEarnings,
    this.todayEarnings,
    this.newOrdersCount,
    this.pendingExtensionRequestsCount,
  });

  factory FetchHomePageUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchHomePageUsecaseModel(
      totalBookings: _asInt(json['totalBookings']),
      todayCount: _asInt(json['todayCount']),
      completedCount: _asInt(json['completedCount']),
      pendingCount: _asInt(json['pendingCount']),
      inProgressCount: _asInt(json['inProgressCount']),
      cancelledCount: _asInt(json['cancelledCount']),
      totalEarnings: _asDouble(json['totalEarnings']),
      todayEarnings: _asDouble(json['todayEarnings']),
      newOrdersCount: _asInt(json['newOrdersCount']),
      pendingExtensionRequestsCount: _asInt(json['pendingExtensionRequestsCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'todayCount': todayCount,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'inProgressCount': inProgressCount,
      'cancelledCount': cancelledCount,
      'totalEarnings': totalEarnings,
      'todayEarnings': todayEarnings,
      'newOrdersCount': newOrdersCount,
      'pendingExtensionRequestsCount': pendingExtensionRequestsCount,
    };
  }
}