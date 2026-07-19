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
  final num? depositBalance;
  final num? debtBalance;
  final num? depositedTotal;
  final num? withdrawnTotal;
  final num? allowedDebtLimit;
  final num? remainingDebtCapacity;
  final num? activeReservedCommission;
  final num? availableCommissionCapacity;
  final num? manualDebtAmount;
  final num? adminCommissionDebtAmount;
  final String? status;
  final num? exceedanceAmount;
  final bool? isEligibleForNewRequests;
  final String? createdAt;
  final String? updatedAt;

  const FetchDepositAccountUsecaseModel({
    this.workerId,
    this.depositBalance,
    this.debtBalance,
    this.depositedTotal,
    this.withdrawnTotal,
    this.allowedDebtLimit,
    this.remainingDebtCapacity,
    this.activeReservedCommission,
    this.availableCommissionCapacity,
    this.manualDebtAmount,
    this.adminCommissionDebtAmount,
    this.status,
    this.exceedanceAmount,
    this.isEligibleForNewRequests,
    this.createdAt,
    this.updatedAt,
  });

  num get currentBalance => depositBalance ?? 0;
  num get debtAmount => debtBalance ?? 0;
  num get minimumRequired => 0;

  factory FetchDepositAccountUsecaseModel.fromJson(Map<String, dynamic> json) {
    final parsedDeposit = _toNum(
      _pick(json, const <String>[
        'depositBalance',
        'deposit_balance',
        'currentBalance',
        'current_balance',
      ]),
    );
    final parsedDebt = _toNum(
      _pick(json, const <String>[
        'debtBalance',
        'debt_balance',
        'debtAmount',
        'debt_amount',
        'commissionDue',
        'commission_due',
      ]),
    );

    return FetchDepositAccountUsecaseModel(
      workerId: _toInt(_pick(json, const <String>['workerId', 'worker_id'])),
      depositBalance: parsedDeposit == null || parsedDeposit < 0
          ? 0
          : parsedDeposit,
      debtBalance: parsedDebt == null || parsedDebt < 0 ? 0 : parsedDebt,
      depositedTotal: _toNum(
        _pick(json, const <String>['depositedTotal', 'deposited_total']),
      ),
      withdrawnTotal: _toNum(
        _pick(json, const <String>['withdrawnTotal', 'withdrawn_total']),
      ),
      allowedDebtLimit: _toNum(
        _pick(json, const <String>[
          'allowedDebtLimit',
          'allowed_debt_limit',
          'maxNegativeBalance',
          'max_negative_balance',
        ]),
      ),
      remainingDebtCapacity: _toNum(
        _pick(json, const <String>[
          'remainingDebtCapacity',
          'remaining_debt_capacity',
        ]),
      ),
      activeReservedCommission: _toNum(
        _pick(json, const <String>[
          'activeReservedCommission',
          'active_reserved_commission',
        ]),
      ),
      availableCommissionCapacity: _toNum(
        _pick(json, const <String>[
          'availableCommissionCapacity',
          'available_commission_capacity',
        ]),
      ),
      manualDebtAmount: _toNum(
        _pick(json, const <String>['manualDebtAmount', 'manual_debt_amount']),
      ),
      adminCommissionDebtAmount: _toNum(
        _pick(json, const <String>[
          'adminCommissionDebtAmount',
          'admin_commission_debt_amount',
        ]),
      ),
      status: _toStringValue(_pick(json, const <String>['status'])),
      exceedanceAmount: _toNum(
        _pick(json, const <String>['exceedanceAmount', 'exceedance_amount']),
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
      'depositBalance': depositBalance,
      'currentBalance': currentBalance,
      'debtBalance': debtBalance,
      'debtAmount': debtAmount,
      'depositedTotal': depositedTotal,
      'withdrawnTotal': withdrawnTotal,
      'allowedDebtLimit': allowedDebtLimit,
      'remainingDebtCapacity': remainingDebtCapacity,
      'activeReservedCommission': activeReservedCommission,
      'availableCommissionCapacity': availableCommissionCapacity,
      'manualDebtAmount': manualDebtAmount,
      'adminCommissionDebtAmount': adminCommissionDebtAmount,
      'status': status,
      'exceedanceAmount': exceedanceAmount,
      'isEligibleForNewRequests': isEligibleForNewRequests,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
