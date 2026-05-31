import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_deposit_transactions_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchDepositTransactionsUsecaseModel parsing', () {
    test('parses transactions payload and meta', () {
      final model = fetchDepositTransactionsUsecaseModelFromJson(
        <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1001,
              'type': 'deposit',
              'amount': 100.0,
              'balanceBefore': 0.0,
              'balanceAfter': 100.0,
              'reference': 'BANK-TXN-001',
              'notes': 'Initial deposit',
              'createdAt': '2026-05-20T10:30:00Z',
              'updatedAt': '2026-05-20T10:30:00Z',
            },
            <String, dynamic>{
              'id': 1002,
              'type': 'withdrawal',
              'amount': '50.00',
              'balance_before': '100.00',
              'balance_after': '50.00',
              'reference': 'ADM-WDR-001',
              'notes': null,
              'created_at': '2026-05-25T15:45:00Z',
              'updated_at': '2026-05-25T15:45:00Z',
            },
          ],
          'meta': <String, dynamic>{
            'currentPage': 1,
            'last_page': '3',
            'perPage': 20,
            'total': '50',
          },
        },
      );

      expect(model.data, isNotNull);
      expect(model.data!.length, 2);

      final first = model.data!.first;
      expect(first.id, 1001);
      expect(first.type, 'deposit');
      expect(first.amount, 100);
      expect(first.balanceBefore, 0);
      expect(first.balanceAfter, 100);
      expect(first.reference, 'BANK-TXN-001');
      expect(first.notes, 'Initial deposit');
      expect(first.createdAt, '2026-05-20T10:30:00Z');
      expect(first.updatedAt, '2026-05-20T10:30:00Z');

      final second = model.data![1];
      expect(second.id, 1002);
      expect(second.type, 'withdrawal');
      expect(second.amount, 50);
      expect(second.balanceBefore, 100);
      expect(second.balanceAfter, 50);
      expect(second.reference, 'ADM-WDR-001');
      expect(second.notes, isNull);
      expect(second.createdAt, '2026-05-25T15:45:00Z');
      expect(second.updatedAt, '2026-05-25T15:45:00Z');

      expect(model.meta, isNotNull);
      expect(model.meta!.currentPage, 1);
      expect(model.meta!.lastPage, 3);
      expect(model.meta!.perPage, 20);
      expect(model.meta!.total, 50);
    });
  });
}
