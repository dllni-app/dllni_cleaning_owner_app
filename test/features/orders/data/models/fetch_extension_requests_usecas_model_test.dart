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

  test('extension consent requires a complete authoritative quote', () {
    final valid = FetchExtensionRequestsUsecasModelDataItem.fromJson(
      const <String, dynamic>{
        'additionalMinutes': 45,
        'baseAmount': 50,
        'adminMargin': 10,
        'totalAmount': 60,
        'additionalAmount': 60,
        'currency': 'SYP',
      },
    );
    final missingBreakdown = FetchExtensionRequestsUsecasModelDataItem.fromJson(
      const <String, dynamic>{
        'additionalMinutes': 45,
        'totalAmount': 60,
        'additionalAmount': 60,
        'currency': 'SYP',
      },
    );

    expect(valid.hasValidWorkerConsentTerms, isTrue);
    expect(valid.authoritativeQuoteAmount, 60);
    expect(missingBreakdown.hasValidWorkerConsentTerms, isFalse);

    final explicitZero = FetchExtensionRequestsUsecasModelDataItem.fromJson(
      const <String, dynamic>{
        'additionalMinutes': 15,
        'baseAmount': 0,
        'adminMargin': 0,
        'totalAmount': 0,
        'additionalAmount': 0,
        'currency': 'SYP',
      },
    );
    expect(explicitZero.hasValidWorkerConsentTerms, isTrue);
  });

  test('extension consent rejects conflicting or invalid financial terms', () {
    final invalidPayloads = <Map<String, dynamic>>[
      {
        'additionalMinutes': 0,
        'baseAmount': 50,
        'adminMargin': 10,
        'totalAmount': 60,
        'additionalAmount': 60,
        'currency': 'SYP',
      },
      {
        'additionalMinutes': 45,
        'baseAmount': 50,
        'adminMargin': 10,
        'totalAmount': 61,
        'additionalAmount': 60,
        'currency': 'SYP',
      },
      {
        'additionalMinutes': 45,
        'baseAmount': 50,
        'adminMargin': -1,
        'totalAmount': 60,
        'additionalAmount': 60,
        'currency': 'SYP',
      },
      {
        'additionalMinutes': 45,
        'baseAmount': 50,
        'adminMargin': 10,
        'totalAmount': double.nan,
        'additionalAmount': 60,
        'currency': 'SYP',
      },
      {
        'additionalMinutes': 45,
        'baseAmount': 50,
        'adminMargin': 10,
        'totalAmount': 60,
        'additionalAmount': double.infinity,
        'currency': 'SYP',
      },
      {
        'additionalMinutes': 45,
        'baseAmount': 50,
        'adminMargin': 10,
        'totalAmount': -1,
        'additionalAmount': 60,
        'currency': 'SYP',
      },
    ];

    for (final payload in invalidPayloads) {
      expect(
        FetchExtensionRequestsUsecasModelDataItem.fromJson(
          payload,
        ).hasValidWorkerConsentTerms,
        isFalse,
        reason: 'Invalid terms must not permit worker acceptance: $payload',
      );
    }
  });
}
