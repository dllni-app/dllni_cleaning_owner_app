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
        'allowedDebtLimit': 50000,
        'remainingDebtCapacity': 50000,
        'activeReservedCommission': 5000,
        'availableCommissionCapacity': 45200.5,
        'manualDebtAmount': 0,
        'adminCommissionDebtAmount': 0,
        'status': 'active',
        'exceedanceAmount': null,
        'isEligibleForNewRequests': true,
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
      expect(model.allowedDebtLimit, 50000);
      expect(model.remainingDebtCapacity, 50000);
      expect(model.activeReservedCommission, 5000);
      expect(model.availableCommissionCapacity, 45200.5);
      expect(model.minimumRequired, 0);
      expect(model.isEligibleForNewRequests, isTrue);
    });

    test('parses snake_case and legacy compatibility aliases', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'worker_id': '42',
        'current_balance': '0',
        'debt_amount': '148.50',
        'deposited_total': 381,
        'withdrawn_total': '180.50',
        'max_negative_balance': '500.00',
        'remaining_debt_capacity': '351.50',
        'active_reserved_commission': '10',
        'available_commission_capacity': '341.50',
        'status': 'active',
        'is_eligible_for_new_requests': '1',
      });

      expect(model.workerId, 42);
      expect(model.depositBalance, 0);
      expect(model.debtBalance, 148.5);
      expect(model.allowedDebtLimit, 500);
      expect(model.remainingDebtCapacity, 351.5);
      expect(model.activeReservedCommission, 10);
      expect(model.availableCommissionCapacity, 341.5);
      expect(model.isEligibleForNewRequests, isTrue);
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
