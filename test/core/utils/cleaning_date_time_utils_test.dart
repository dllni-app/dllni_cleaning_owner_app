import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_date_time_parser.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_relative_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CleaningDateTimeParser', () {
    test('parses mysql-style timestamps as UTC', () {
      final parsed = CleaningDateTimeParser.tryParseBackendUtc(
        '2026-06-20 10:00:00',
      );

      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isFalse);
      expect(parsed.toUtc(), DateTime.utc(2026, 6, 20, 10));
    });
  });

  group('CleaningRelativeTimeFormatter', () {
    test('formats recent backend createdAt', () {
      final nowUtc = DateTime.now().toUtc();
      final fiveMinutesAgo =
          nowUtc.subtract(const Duration(minutes: 5)).toIso8601String();

      final label =
          CleaningRelativeTimeFormatter.fromBackendCreatedAt(fiveMinutesAgo);

      expect(label, contains('5'));
      expect(label, contains('دقيقة'));
    });
  });
}
