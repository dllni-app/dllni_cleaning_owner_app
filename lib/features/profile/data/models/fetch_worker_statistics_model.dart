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

FetchWorkerStatisticsModel fetchWorkerStatisticsModelFromJson(str) => FetchWorkerStatisticsModel.fromJson(str);

String fetchWorkerStatisticsModelToJson(FetchWorkerStatisticsModel data) => json.encode(data.toJson());


FetchWorkerStatisticsModelChartItem fetchWorkerStatisticsModelChartItemFromJson(str) => FetchWorkerStatisticsModelChartItem.fromJson(str);

String fetchWorkerStatisticsModelChartItemToJson(FetchWorkerStatisticsModelChartItem data) => json.encode(data.toJson());


FetchWorkerStatisticsModelSummary fetchWorkerStatisticsModelSummaryFromJson(str) => FetchWorkerStatisticsModelSummary.fromJson(str);

String fetchWorkerStatisticsModelSummaryToJson(FetchWorkerStatisticsModelSummary data) => json.encode(data.toJson());


class FetchWorkerStatisticsModel {
  String? range;
  FetchWorkerStatisticsModelSummary? summary;
  List<FetchWorkerStatisticsModelChartItem>? chart;

  FetchWorkerStatisticsModel({
    this.range,
    this.summary,
    this.chart,
  });

  factory FetchWorkerStatisticsModel.fromJson(Map<String, dynamic> json) {
    return FetchWorkerStatisticsModel(
      range: _asString(json['range']),
      summary: json['summary'] is Map ? FetchWorkerStatisticsModelSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map)) : null,
      chart: json['chart'] is List ? (json['chart'] as List).whereType<Map>().map((item) => FetchWorkerStatisticsModelChartItem.fromJson(Map<String, dynamic>.from(item))).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'range': range,
      'summary': summary?.toJson(),
      'chart': chart?.map((item) => item.toJson()).toList(),
    };
  }
}

class FetchWorkerStatisticsModelChartItem {
  String? date;
  String? confirmed;
  String? cancelled;
  String? disputed;

  FetchWorkerStatisticsModelChartItem({
    this.date,
    this.confirmed,
    this.cancelled,
    this.disputed,
  });

  factory FetchWorkerStatisticsModelChartItem.fromJson(Map<String, dynamic> json) {
    return FetchWorkerStatisticsModelChartItem(
      date: _asString(json['date']),
      confirmed: _asString(json['confirmed']),
      cancelled: _asString(json['cancelled']),
      disputed: _asString(json['disputed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'confirmed': confirmed,
      'cancelled': cancelled,
      'disputed': disputed,
    };
  }
}

class FetchWorkerStatisticsModelSummary {
  int? totalBookings;
  int? totalEarnings;
  int? confirmedCount;
  int? cancelledCount;
  int? disputedCount;

  FetchWorkerStatisticsModelSummary({
    this.totalBookings,
    this.totalEarnings,
    this.confirmedCount,
    this.cancelledCount,
    this.disputedCount,
  });

  factory FetchWorkerStatisticsModelSummary.fromJson(Map<String, dynamic> json) {
    return FetchWorkerStatisticsModelSummary(
      totalBookings: _asInt(json['totalBookings']),
      totalEarnings: _asInt(json['totalEarnings']),
      confirmedCount: _asInt(json['confirmedCount']),
      cancelledCount: _asInt(json['cancelledCount']),
      disputedCount: _asInt(json['disputedCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'totalEarnings': totalEarnings,
      'confirmedCount': confirmedCount,
      'cancelledCount': cancelledCount,
      'disputedCount': disputedCount,
    };
  }
}