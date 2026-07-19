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

    test('formatScheduledDate includes Arabic weekday', () {
      // 2026-07-16 is Thursday
      expect(
        CleaningArabicTimeFormatter.formatScheduledDate('2026-07-16'),
        'الخميس 2026-07-16',
      );
      expect(
        CleaningArabicTimeFormatter.formatScheduledDate(
          '2026-07-17',
          includeWeekday: false,
        ),
        '2026-07-17',
      );
      expect(
        CleaningArabicTimeFormatter.formatScheduledDate(null),
        '-',
      );
    });

    test('formatScheduledWeekday returns Arabic day name', () {
      expect(
        CleaningArabicTimeFormatter.formatScheduledWeekday('2026-07-16'),
        'الخميس',
      );
      expect(
        CleaningArabicTimeFormatter.formatScheduledWeekday('2026-07-17'),
        'الجمعة',
      );
      expect(
        CleaningArabicTimeFormatter.formatScheduledWeekday(null),
        '-',
      );
    });

    test('toArabicDigits converts western digits', () {
      expect(CleaningArabicTimeFormatter.toArabicDigits('19'), '١٩');
      expect(CleaningArabicTimeFormatter.toArabicDigits('2026-07-20'), '٢٠٢٦-٠٧-٢٠');
      expect(CleaningArabicTimeFormatter.toArabicDigits('July 19_25'), 'July ١٩_٢٥');
    });

    test('arabicMonthName returns Arabic month', () {
      expect(
        CleaningArabicTimeFormatter.arabicMonthName(DateTime(2026, 7, 19)),
        'يوليو',
      );
      expect(
        CleaningArabicTimeFormatter.arabicMonthName(DateTime(2026, 1, 1)),
        'يناير',
      );
    });

    test('arabicWeekdayShortName returns short Arabic weekday', () {
      // 2026-07-19 is Sunday
      expect(
        CleaningArabicTimeFormatter.arabicWeekdayShortName(DateTime(2026, 7, 19)),
        'أحد',
      );
      // 2026-07-20 is Monday
      expect(
        CleaningArabicTimeFormatter.arabicWeekdayShortName(DateTime(2026, 7, 20)),
        'إثن',
      );
    });

    test('formatCalendarWeekRange uses Arabic month and digits', () {
      final focused = DateTime(2026, 7, 19);
      expect(
        CleaningArabicTimeFormatter.formatCalendarWeekRange(focused),
        'يوليو ١٩_٢٥',
      );
    });

    test('formatCalendarSelectedDate uses Arabic month and digits', () {
      expect(
        CleaningArabicTimeFormatter.formatCalendarSelectedDate(
          DateTime(2026, 7, 19),
        ),
        '١٩ يوليو ٢٠٢٦',
      );
    });

    test('formatCalendarDayNumber uses Eastern digits', () {
      expect(
        CleaningArabicTimeFormatter.formatCalendarDayNumber(DateTime(2026, 7, 19)),
        '١٩',
      );
    });

    test('formatCalendarIsoDate converts iso date digits', () {
      expect(
        CleaningArabicTimeFormatter.formatCalendarIsoDate('2026-07-20'),
        '٢٠٢٦-٠٧-٢٠',
      );
      expect(CleaningArabicTimeFormatter.formatCalendarIsoDate(null), '-');
    });
  });
}
