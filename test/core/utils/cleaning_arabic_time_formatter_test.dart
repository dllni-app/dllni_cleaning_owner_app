import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('CleaningArabicTimeFormatter', () {
    test('replaceAmPmWithArabic converts AM and PM', () {
      expect(
        CleaningArabicTimeFormatter.replaceAmPmWithArabic('09:00 AM'),
        '09:00 ص',
      );
      expect(
        CleaningArabicTimeFormatter.replaceAmPmWithArabic('9:00 pm'),
        '9:00 م',
      );
    });

    test('formatScheduledTime parses HH:mm:ss with Arabic period', () {
      expect(
        CleaningArabicTimeFormatter.formatScheduledTime('09:00:00'),
        '09:00 ص',
      );
      expect(
        CleaningArabicTimeFormatter.formatScheduledTime('21:30:00'),
        '09:30 م',
      );
    });

    test('formatDateTime includes Arabic period', () {
      final formatted = CleaningArabicTimeFormatter.formatDateTime(
        '2026-06-22T09:00:00',
      );
      expect(formatted, isNot(contains('AM')));
      expect(formatted, isNot(contains('PM')));
      expect(formatted, anyOf(contains('ص'), contains('م')));
    });
  });
}
