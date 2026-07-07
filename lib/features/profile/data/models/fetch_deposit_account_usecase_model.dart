import 'dart:convert';

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
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

bool? _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

FetchDepositAccountUsecaseModel fetchDepositAccountUsecaseModelFromJson(
  dynamic json,
) => FetchDepositAccountUsecaseModel.fromJson(_toMap(json));

String fetchDepositAccountUsecaseModelToJson(
  FetchDepositAccountUsecaseModel data,
) => jsonEncode(data.toJson());

class FetchDepositAccountUsecaseModel {
  final int? workerId;
  final num? currentBalance;
  final num? depositedTotal;
  final num? withdrawnTotal;
  final num? minimumRequired;
  final String? status;
  final num? exceedanceAmount;
  final num? rawDebtAmount;
  final bool? isEligibleForNewRequests;
  final String? createdAt;
  final String? updatedAt;

  const FetchDepositAccountUsecaseModel({
    this.workerId,
    this.currentBalance,
    this.depositedTotal,
    this.withdrawnTotal,
    this.minimumRequired,
    this.status,
    this.exceedanceAmount,
    this.rawDebtAmount,
    this.isEligibleForNewRequests,
    this.createdAt,
    this.updatedAt,
  });

  /// Outstanding admin debt owed by the worker.
  ///
  /// Newer API responses may send this as `debtAmount` / `debt_amount`.
  /// Older responses already contain the enough balance fields to derive it:
  /// deposited principal - withdrawals - current balance.
  num get debtAmount {
    if (rawDebtAmount != null) return rawDebtAmount! < 0 ? 0 : rawDebtAmount!;

    final calculated = (depositedTotal ?? 0) - (withdrawnTotal ?? 0) - (currentBalance ?? 0);
    return calculated > 0 ? calculated : 0;
  }

  factory FetchDepositAccountUsecaseModel.fromJson(Map<String, dynamic> json) {
    return FetchDepositAccountUsecaseModel(
      workerId: _toInt(_pick(json, const <String>['workerId', 'worker_id'])),
      currentBalance: _toNum(
        _pick(json, const <String>['currentBalance', 'current_balance']),
      ),
      depositedTotal: _toNum(
        _pick(json, const <String>['depositedTotal', 'deposited_total']),
      ),
      withdrawnTotal: _toNum(
        _pick(json, const <String>['withdrawnTotal', 'withdrawn_total']),
      ),
      minimumRequired: _toNum(
        _pick(json, const <String>['minimumRequired', 'minimum_required']),
      ),
      status: _toStringValue(_pick(json, const <String>['status'])),
      exceedanceAmount: _toNum(
        _pick(json, const <String>['exceedanceAmount', 'exceedance_amount']),
      ),
      rawDebtAmount: _toNum(
        _pick(json, const <String>['debtAmount', 'debt_amount', 'commissionDue', 'commission_due']),
      ),
      isEligibleForNewRequests: _toBool(
        _pick(json, const <String>[
          'isEligibleForNewRequests',
          'is_eligible_for_new_requests',
        ]),
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
      'workerId': workerId,
      'currentBalance': currentBalance,
      'depositedTotal': depositedTotal,
      'withdrawnTotal': withdrawnTotal,
      'minimumRequired': minimumRequired,
      'status': status,
      'exceedanceAmount': exceedanceAmount,
      'debtAmount': debtAmount,
      'isEligibleForNewRequests': isEligibleForNewRequests,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
