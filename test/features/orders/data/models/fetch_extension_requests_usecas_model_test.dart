import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_extension_requests_usecas_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses extension amount breakdown from numbers and numeric strings',
    () {
      final item = FetchExtensionRequestsUsecasModelDataItem.fromJson(
        const <String, dynamic>{
          'id': 7,
          'baseAmount': '4500',
          'adminMargin': 500,
          'totalAmount': '5000.00',
          'additionalAmount': 5000,
          'currency': 'SYP',
        },
      );

      expect(item.baseAmount, 4500);
      expect(item.adminMargin, 500);
      expect(item.totalAmount, 5000);
      expect(item.additionalAmount, 5000);
      expect(item.currency, 'SYP');
    },
  );

  test('keeps legacy total when breakdown fields are absent', () {
    final item = FetchExtensionRequestsUsecasModelDataItem.fromJson(
      const <String, dynamic>{'additionalAmount': '5000', 'currency': 'SYP'},
    );

    expect(item.baseAmount, isNull);
    expect(item.adminMargin, isNull);
    expect(item.totalAmount, isNull);
    expect(item.additionalAmount, 5000);
  });
}
