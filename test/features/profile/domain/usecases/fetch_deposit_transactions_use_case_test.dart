import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_deposit_transactions_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchDepositTransactionsParams', () {
    test('builds query params with optional type', () {
      final withType = FetchDepositTransactionsParams(
        page: 2,
        perPage: 20,
        type: 'deposit',
      );
      final withoutType = FetchDepositTransactionsParams(page: 1, perPage: 20);

      expect(withType.getParams(), <String, dynamic>{
        'page': '2',
        'perPage': '20',
        'type': 'deposit',
      });

      expect(withoutType.getParams(), <String, dynamic>{
        'page': '1',
        'perPage': '20',
      });
    });
  });
}
