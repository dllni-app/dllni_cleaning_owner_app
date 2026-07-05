import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_deposit_account_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchDepositAccountUsecaseModel parsing', () {
    test('parses camelCase payload', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'workerId': 42,
        'currentBalance': 200.5,
        'depositedTotal': 381.0,
        'withdrawnTotal': 180.5,
        'minimumRequired': 381.0,
        'status': 'insufficient_balance',
        'exceedanceAmount': 100.5,
        'debtAmount': 148.5,
        'isEligibleForNewRequests': false,
        'createdAt': '2026-05-20T10:30:00Z',
        'updatedAt': '2026-05-30T14:22:00Z',
      });

      expect(model.workerId, 42);
      expect(model.currentBalance, 200.5);
      expect(model.depositedTotal, 381);
      expect(model.withdrawnTotal, 180.5);
      expect(model.minimumRequired, 381);
      expect(model.status, 'insufficient_balance');
      expect(model.exceedanceAmount, 100.5);
      expect(model.debtAmount, 148.5);
      expect(model.isEligibleForNewRequests, isFalse);
      expect(model.createdAt, '2026-05-20T10:30:00Z');
      expect(model.updatedAt, '2026-05-30T14:22:00Z');
    });

    test('parses snake_case and coercible values', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'worker_id': '42',
        'current_balance': '200.50',
        'deposited_total': 381,
        'withdrawn_total': '180.50',
        'minimum_required': '381.00',
        'status': 'active',
        'exceedance_amount': null,
        'debt_amount': '148.50',
        'is_eligible_for_new_requests': '1',
        'created_at': '2026-05-20T10:30:00Z',
        'updated_at': '2026-05-30T14:22:00Z',
      });

      expect(model.workerId, 42);
      expect(model.currentBalance, 200.5);
      expect(model.depositedTotal, 381);
      expect(model.withdrawnTotal, 180.5);
      expect(model.minimumRequired, 381);
      expect(model.status, 'active');
      expect(model.exceedanceAmount, isNull);
      expect(model.debtAmount, 148.5);
      expect(model.isEligibleForNewRequests, isTrue);
      expect(model.createdAt, '2026-05-20T10:30:00Z');
      expect(model.updatedAt, '2026-05-30T14:22:00Z');
    });

    test('derives debt amount from existing balance fields when API does not send it', () {
      final model = fetchDepositAccountUsecaseModelFromJson(<String, dynamic>{
        'currentBalance': 851500,
        'depositedTotal': 1000000,
        'withdrawnTotal': 0,
      });

      expect(model.debtAmount, 148500);
    });
  });
}
