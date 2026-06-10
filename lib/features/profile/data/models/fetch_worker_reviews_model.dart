import 'dart:convert';

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value.map((item) => _toMap(item)).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

dynamic _pick(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null) return value;
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

num? _toNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

String? _toStringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

FetchWorkerReviewsModel fetchWorkerReviewsModelFromJson(dynamic json) =>
    FetchWorkerReviewsModel.fromJson(_toMap(json));

String fetchWorkerReviewsModelToJson(FetchWorkerReviewsModel data) =>
    jsonEncode(data.toJson());

class FetchWorkerReviewsModel {
  final List<WorkerReview>? data;
  final ReviewsMeta? meta;

  const FetchWorkerReviewsModel({this.data, this.meta});

  factory FetchWorkerReviewsModel.fromJson(Map<String, dynamic> json) {
    return FetchWorkerReviewsModel(
      data: _toMapList(json['data'])
          .map(WorkerReview.fromJson)
          .toList(growable: false),
      meta: json['meta'] == null
          ? null
          : ReviewsMeta.fromJson(_toMap(json['meta'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': data?.map((item) => item.toJson()).toList(growable: false),
      'meta': meta?.toJson(),
    };
  }
}

class WorkerReview {
  final int? id;
  final String? customerName;
  final double? rating;
  final String? comment;
  final String? createdAt;

  const WorkerReview({
    this.id,
    this.customerName,
    this.rating,
    this.comment,
    this.createdAt,
  });

  factory WorkerReview.fromJson(Map<String, dynamic> json) {
    return WorkerReview(
      id: _toInt(_pick(json, const <String>['id'])),
      customerName: _toStringValue(
        _pick(json, const <String>['customerName', 'customer_name']),
      ),
      rating: _toNum(_pick(json, const <String>['rating']))?.toDouble(),
      comment: _toStringValue(_pick(json, const <String>['comment'])),
      createdAt: _toStringValue(
        _pick(json, const <String>['createdAt', 'created_at']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}

class ReviewsMeta {
  final double? averageRating;
  final int? totalCount;
  final int? currentPage;
  final int? lastPage;
  final int? perPage;

  const ReviewsMeta({
    this.averageRating,
    this.totalCount,
    this.currentPage,
    this.lastPage,
    this.perPage,
  });

  factory ReviewsMeta.fromJson(Map<String, dynamic> json) {
    return ReviewsMeta(
      averageRating: _toNum(
        _pick(json, const <String>['averageRating', 'average_rating']),
      )?.toDouble(),
      totalCount: _toInt(
        _pick(json, const <String>['totalCount', 'total_count', 'total']),
      ),
      currentPage: _toInt(
        _pick(json, const <String>['currentPage', 'current_page']),
      ),
      lastPage: _toInt(_pick(json, const <String>['lastPage', 'last_page'])),
      perPage: _toInt(_pick(json, const <String>['perPage', 'per_page'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'averageRating': averageRating,
      'totalCount': totalCount,
      'currentPage': currentPage,
      'lastPage': lastPage,
      'perPage': perPage,
    };
  }
}
