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

FetchDepositTransactionsUsecaseModel
fetchDepositTransactionsUsecaseModelFromJson(dynamic json) =>
    FetchDepositTransactionsUsecaseModel.fromJson(_toMap(json));

String fetchDepositTransactionsUsecaseModelToJson(
  FetchDepositTransactionsUsecaseModel data,
) => jsonEncode(data.toJson());

class FetchDepositTransactionsUsecaseModel {
  final List<FetchDepositTransactionsUsecaseModelDataItem>? data;
  final FetchDepositTransactionsUsecaseModelMeta? meta;

  const FetchDepositTransactionsUsecaseModel({this.data, this.meta});

  factory FetchDepositTransactionsUsecaseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchDepositTransactionsUsecaseModel(
      data: _toMapList(json['data'])
          .map(FetchDepositTransactionsUsecaseModelDataItem.fromJson)
          .toList(growable: false),
      meta: json['meta'] == null
          ? null
          : FetchDepositTransactionsUsecaseModelMeta.fromJson(
              _toMap(json['meta']),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': data?.map((item) => item.toJson()).toList(growable: false),
      'meta': meta?.toJson(),
    };
  }
}

class FetchDepositTransactionsUsecaseModelDataItem {
  final int? id;
  final String? type;
  final num? amount;
  final num? balanceBefore;
  final num? balanceAfter;
  final String? reference;
  final String? notes;
  final int? cleaningBookingId;
  final String? createdAt;
  final String? updatedAt;

  const FetchDepositTransactionsUsecaseModelDataItem({
    this.id,
    this.type,
    this.amount,
    this.balanceBefore,
    this.balanceAfter,
    this.reference,
    this.notes,
    this.cleaningBookingId,
    this.createdAt,
    this.updatedAt,
  });

  factory FetchDepositTransactionsUsecaseModelDataItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchDepositTransactionsUsecaseModelDataItem(
      id: _toInt(_pick(json, const <String>['id'])),
      type: _toStringValue(_pick(json, const <String>['type'])),
      amount: _toNum(_pick(json, const <String>['amount'])),
      balanceBefore: _toNum(
        _pick(json, const <String>['balanceBefore', 'balance_before']),
      ),
      balanceAfter: _toNum(
        _pick(json, const <String>['balanceAfter', 'balance_after']),
      ),
      reference: _toStringValue(_pick(json, const <String>['reference'])),
      notes: _toStringValue(_pick(json, const <String>['notes'])),
      cleaningBookingId: _toInt(
        _pick(json, const <String>['cleaningBookingId', 'cleaning_booking_id']),
      ),
      createdAt: _toStringValue(
        _pick(json, const <String>['createdAt', 'created_at']),
      ),
      updatedAt: _toStringValue(
        _pick(json, const <String>['updatedAt', 'updated_at']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'reference': reference,
      'notes': notes,
      'cleaningBookingId': cleaningBookingId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class FetchDepositTransactionsUsecaseModelMeta {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  const FetchDepositTransactionsUsecaseModelMeta({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  factory FetchDepositTransactionsUsecaseModelMeta.fromJson(
    Map<String, dynamic> json,
  ) {
    return FetchDepositTransactionsUsecaseModelMeta(
      currentPage: _toInt(
        _pick(json, const <String>['currentPage', 'current_page']),
      ),
      lastPage: _toInt(_pick(json, const <String>['lastPage', 'last_page'])),
      perPage: _toInt(_pick(json, const <String>['perPage', 'per_page'])),
      total: _toInt(_pick(json, const <String>['total'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentPage': currentPage,
      'lastPage': lastPage,
      'perPage': perPage,
      'total': total,
    };
  }
}
