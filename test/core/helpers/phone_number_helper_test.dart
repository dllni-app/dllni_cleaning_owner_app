import 'package:dllni_cleaninig_owner_app/core/helpers/phone_number_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

void main() {
  group('parseInitialPhone', () {
    test('returns parsed Syrian number for valid SY input', () async {
      final parsed = await parseInitialPhone('+963991234567');

      expect(parsed, isNotNull);
      expect(parsed?.isoCode, defaultPhoneIsoCode);
    });

    test('returns null for non-Syrian input', () async {
      final parsed = await parseInitialPhone('+971501234567');

      expect(parsed, isNull);
    });
  });

  group('validatePhoneNumber', () {
    test('accepts valid Syrian number', () async {
      final error = await validatePhoneNumber(
        PhoneNumber(isoCode: defaultPhoneIsoCode, phoneNumber: '+963991234567'),
      );

      expect(error, isNull);
    });

    test('rejects non-Syrian number', () async {
      final error = await validatePhoneNumber(
        PhoneNumber(isoCode: 'AE', phoneNumber: '+971501234567'),
      );

      expect(error, 'Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„ ØºÙŠØ± ØµØ§Ù„Ø­');
    });

    test('keeps required message for empty value', () async {
      final error = await validatePhoneNumber(
        PhoneNumber(isoCode: defaultPhoneIsoCode, phoneNumber: ''),
      );

      expect(error, 'Ø£Ø¯Ø®Ù„ Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„');
    });

    test('keeps invalid message for malformed value', () async {
      final error = await validatePhoneNumber(
        PhoneNumber(isoCode: defaultPhoneIsoCode, phoneNumber: '+9639'),
      );

      expect(error, 'Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„ ØºÙŠØ± ØµØ§Ù„Ø­');
    });
  });
}
