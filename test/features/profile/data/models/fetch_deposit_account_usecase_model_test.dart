import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_deposit_account_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchDepositAccountUsecaseModel parsing', () {
    test('parses the separate deposit and debt balances', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'workerId': 42,
        'depositBalance': 200.5,
        'debtBalance': 0,
        'depositedTotal': 381.0,
        'withdrawnTotal': 180.5,
        'minimumRequired': 1000,
        'allowedDebtLimit': 35000,
        'configuredAllowedDebtLimit': 50000,
        'remainingDebtCapacity': 35000,
        'remainingAllowanceLimit': 35000,
        'allowanceUsedAmount': 15000,
        'activeReservedCommission': 5000,
        'availableCommissionCapacity': 45200.5,
        'manualDebtAmount': 0,
        'adminCommissionDebtAmount': 0,
        'totalCommission': 20000,
        'adminCommissionBalance': 15000,
        'withdrawnAdminRevenueTotal': 2000,
        'status': 'active',
        'exceedanceAmount': null,
        'isEligibleForNewRequests': true,
        'isAllowanceLimitExhausted': false,
        'isUsingDepositBalance': true,
        'isAllowanceNearLimit': false,
        'allowanceWarningThresholdPercent': 10,
        'financialWarningCode': null,
        'createdAt': '2026-05-20T10:30:00Z',
        'updatedAt': '2026-05-30T14:22:00Z',
      });

      expect(model.workerId, 42);
      expect(model.depositBalance, 200.5);
      expect(model.currentBalance, 200.5);
      expect(model.debtBalance, 0);
      expect(model.debtAmount, 0);
      expect(model.depositedTotal, 381);
      expect(model.withdrawnTotal, 180.5);
      expect(model.allowedDebtLimit, 35000);
      expect(model.configuredAllowedDebtLimit, 50000);
      expect(model.remainingDebtCapacity, 35000);
      expect(model.remainingAllowanceLimit, 35000);
      expect(model.displayAllowedDebtLimit, 35000);
      expect(model.allowanceUsedAmount, 15000);
      expect(model.activeReservedCommission, 5000);
      expect(model.availableCommissionCapacity, 45200.5);
      expect(model.adminCommissionBalance, 15000);
      expect(model.withdrawnAdminRevenueTotal, 2000);
      expect(model.minimumRequired, 1000);
      expect(model.totalCommission, 20000);
      expect(model.isEligibleForNewRequests, isTrue);
      expect(model.isAllowanceLimitExhausted, isFalse);
      expect(model.isUsingDepositBalance, isTrue);
      expect(model.isAllowanceNearLimit, isFalse);
      expect(model.allowanceWarningThresholdPercent, 10);
      expect(model.financialWarningCode, isNull);
    });

    test('parses snake_case and legacy compatibility aliases', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'worker_id': '42',
        'current_balance': '0',
        'debt_amount': '148.50',
        'deposited_total': 381,
        'withdrawn_total': '180.50',
        'minimum_required': '750',
        'allowed_debt_limit': '351.50',
        'configured_allowed_debt_limit': '500.00',
        'max_negative_balance': '500.00',
        'remaining_debt_capacity': '351.50',
        'remaining_allowance_limit': '351.50',
        'allowance_used_amount': '148.50',
        'active_reserved_commission': '10',
        'available_commission_capacity': '341.50',
        'admin_commission_balance': '148.50',
        'withdrawn_admin_revenue_total': '25',
        'status': 'active',
        'is_eligible_for_new_requests': '1',
        'is_allowance_limit_exhausted': '0',
        'is_using_deposit_balance': '0',
        'is_allowance_near_limit': '1',
        'allowance_warning_threshold_percent': '12.5',
        'financial_warning_code': 'allowance_near_limit',
        'financial_warning_message': 'Near limit',
      });

      expect(model.workerId, 42);
      expect(model.depositBalance, 0);
      expect(model.debtBalance, 148.5);
      expect(model.allowedDebtLimit, 351.5);
      expect(model.configuredAllowedDebtLimit, 500);
      expect(model.remainingDebtCapacity, 351.5);
      expect(model.remainingAllowanceLimit, 351.5);
      expect(model.displayAllowedDebtLimit, 351.5);
      expect(model.allowanceUsedAmount, 148.5);
      expect(model.activeReservedCommission, 10);
      expect(model.availableCommissionCapacity, 341.5);
      expect(model.adminCommissionBalance, 148.5);
      expect(model.withdrawnAdminRevenueTotal, 25);
      expect(model.minimumRequired, 750);
      expect(model.isEligibleForNewRequests, isTrue);
      expect(model.isAllowanceLimitExhausted, isFalse);
      expect(model.isUsingDepositBalance, isFalse);
      expect(model.isAllowanceNearLimit, isTrue);
      expect(model.allowanceWarningThresholdPercent, 12.5);
      expect(model.financialWarningCode, 'allowance_near_limit');
      expect(model.financialWarningMessage, 'Near limit');
    });

    test('falls back to allowed debt limit for the displayed allowance', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'allowedDebtLimit': 500,
      });

      expect(model.displayAllowedDebtLimit, 500);
    });

    test('clamps negative balances returned by an old server', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'currentBalance': -100,
        'debtAmount': -50,
      });

      expect(model.depositBalance, 0);
      expect(model.debtBalance, 0);
    });
  });
}
