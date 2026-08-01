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
  final num? minimumRequired;
  final num? allowedDebtLimit;
  final num? configuredAllowedDebtLimit;
  final num? remainingDebtCapacity;
  final num? remainingAllowanceLimit;
  final num? allowanceUsedAmount;
  final num? activeReservedCommission;
  final num? availableCommissionCapacity;
  final num? manualDebtAmount;
  final num? adminCommissionDebtAmount;
  final num? totalRevenue;
  final int? completedJobs;
  final num? totalCommission;
  final num? adminCommissionBalance;
  final num? withdrawnAdminRevenueTotal;
  final num? grossInvoicesAmount;
  final String? status;
  final num? exceedanceAmount;
  final bool? isEligibleForNewRequests;
  final bool? isAllowanceLimitExhausted;
  final bool? isUsingDepositBalance;
  final bool? isAllowanceNearLimit;
  final num? allowanceWarningThresholdPercent;
  final String? financialWarningCode;
  final String? financialWarningMessage;
  final bool? isFinancialAccountActive;
  final String? createdAt;
  final String? updatedAt;

  const FetchDepositAccountUsecaseModel({
    this.workerId,
    this.depositBalance,
    this.debtBalance,
    this.depositedTotal,
    this.withdrawnTotal,
    this.minimumRequired,
    this.allowedDebtLimit,
    this.configuredAllowedDebtLimit,
    this.remainingDebtCapacity,
    this.remainingAllowanceLimit,
    this.allowanceUsedAmount,
    this.activeReservedCommission,
    this.availableCommissionCapacity,
    this.manualDebtAmount,
    this.adminCommissionDebtAmount,
    this.totalRevenue,
    this.completedJobs,
    this.totalCommission,
    this.adminCommissionBalance,
    this.withdrawnAdminRevenueTotal,
    this.grossInvoicesAmount,
    this.status,
    this.exceedanceAmount,
    this.isEligibleForNewRequests,
    this.isAllowanceLimitExhausted,
    this.isUsingDepositBalance,
    this.isAllowanceNearLimit,
    this.allowanceWarningThresholdPercent,
    this.financialWarningCode,
    this.financialWarningMessage,
    this.isFinancialAccountActive,
    this.createdAt,
    this.updatedAt,
  });

  num get currentBalance => depositBalance ?? 0;
  num get debtAmount => debtBalance ?? 0;
  num get displayAllowedDebtLimit =>
      remainingAllowanceLimit ?? allowedDebtLimit ?? 0;

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
      minimumRequired:
          _toNum(
            _pick(json, const <String>['minimumRequired', 'minimum_required']),
          ) ??
          0,
      allowedDebtLimit: _toNum(
        _pick(json, const <String>[
          'allowedDebtLimit',
          'allowed_debt_limit',
          'maxNegativeBalance',
          'max_negative_balance',
        ]),
      ),
      configuredAllowedDebtLimit: _toNum(
        _pick(json, const <String>[
          'configuredAllowedDebtLimit',
          'configured_allowed_debt_limit',
        ]),
      ),
      remainingDebtCapacity: _toNum(
        _pick(json, const <String>[
          'remainingDebtCapacity',
          'remaining_debt_capacity',
        ]),
      ),
      remainingAllowanceLimit: _toNum(
        _pick(json, const <String>[
          'remainingAllowanceLimit',
          'remaining_allowance_limit',
        ]),
      ),
      allowanceUsedAmount: _toNum(
        _pick(json, const <String>[
          'allowanceUsedAmount',
          'allowance_used_amount',
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
      totalRevenue: _toNum(
        _pick(json, const <String>['totalRevenue', 'total_revenue']),
      ),
      completedJobs: _toInt(
        _pick(json, const <String>['completedJobs', 'completed_jobs']),
      ),
      totalCommission: _toNum(
        _pick(json, const <String>['totalCommission', 'total_commission']),
      ),
      adminCommissionBalance: _toNum(
        _pick(json, const <String>[
          'adminCommissionBalance',
          'admin_commission_balance',
        ]),
      ),
      withdrawnAdminRevenueTotal: _toNum(
        _pick(json, const <String>[
          'withdrawnAdminRevenueTotal',
          'withdrawn_admin_revenue_total',
        ]),
      ),
      grossInvoicesAmount: _toNum(
        _pick(json, const <String>[
          'grossInvoicesAmount',
          'gross_invoices_amount',
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
      isAllowanceLimitExhausted: _toBool(
        _pick(json, const <String>[
          'isAllowanceLimitExhausted',
          'is_allowance_limit_exhausted',
        ]),
      ),
      isUsingDepositBalance: _toBool(
        _pick(json, const <String>[
          'isUsingDepositBalance',
          'is_using_deposit_balance',
        ]),
      ),
      isAllowanceNearLimit: _toBool(
        _pick(json, const <String>[
          'isAllowanceNearLimit',
          'is_allowance_near_limit',
        ]),
      ),
      allowanceWarningThresholdPercent:
          _toNum(
            _pick(json, const <String>[
              'allowanceWarningThresholdPercent',
              'allowance_warning_threshold_percent',
            ]),
          ) ??
          10,
      financialWarningCode: _toStringValue(
        _pick(json, const <String>[
          'financialWarningCode',
          'financial_warning_code',
        ]),
      ),
      financialWarningMessage: _toStringValue(
        _pick(json, const <String>[
          'financialWarningMessage',
          'financial_warning_message',
        ]),
      ),
      isFinancialAccountActive: _toBool(
        _pick(json, const <String>[
          'isFinancialAccountActive',
          'is_financial_account_active',
          'isActive',
          'is_active',
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
      'minimumRequired': minimumRequired,
      'allowedDebtLimit': allowedDebtLimit,
      'configuredAllowedDebtLimit': configuredAllowedDebtLimit,
      'remainingDebtCapacity': remainingDebtCapacity,
      'remainingAllowanceLimit': remainingAllowanceLimit,
      'allowanceUsedAmount': allowanceUsedAmount,
      'activeReservedCommission': activeReservedCommission,
      'availableCommissionCapacity': availableCommissionCapacity,
      'manualDebtAmount': manualDebtAmount,
      'adminCommissionDebtAmount': adminCommissionDebtAmount,
      'totalRevenue': totalRevenue,
      'completedJobs': completedJobs,
      'totalCommission': totalCommission,
      'adminCommissionBalance': adminCommissionBalance,
      'withdrawnAdminRevenueTotal': withdrawnAdminRevenueTotal,
      'grossInvoicesAmount': grossInvoicesAmount,
      'status': status,
      'exceedanceAmount': exceedanceAmount,
      'isEligibleForNewRequests': isEligibleForNewRequests,
      'isAllowanceLimitExhausted': isAllowanceLimitExhausted,
      'isUsingDepositBalance': isUsingDepositBalance,
      'isAllowanceNearLimit': isAllowanceNearLimit,
      'allowanceWarningThresholdPercent': allowanceWarningThresholdPercent,
      'financialWarningCode': financialWarningCode,
      'financialWarningMessage': financialWarningMessage,
      'isFinancialAccountActive': isFinancialAccountActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
