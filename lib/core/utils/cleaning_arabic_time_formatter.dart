import 'package:intl/intl.dart';

class CleaningArabicTimeFormatter {
  const CleaningArabicTimeFormatter._();

  static String replaceAmPmWithArabic(String formatted) {
    return formatted
        .replaceAll(RegExp(r'\bAM\b', caseSensitive: false), 'ص')
        .replaceAll(RegExp(r'\bPM\b', caseSensitive: false), 'م')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String format(
    DateTime dateTime, {
    String pattern = 'hh:mm a',
  }) {
    return replaceAmPmWithArabic(DateFormat(pattern, 'en').format(dateTime));
  }

  static String formatScheduledTime(
    String? rawTime, {
    String pattern = 'hh:mm a',
    String emptyValue = '-',
  }) {
    if (rawTime == null || rawTime.trim().isEmpty) return emptyValue;
    final value = rawTime.trim();

    try {
      final parsed = DateFormat('HH:mm:ss', 'en').parseStrict(value);
      return format(parsed, pattern: pattern);
    } catch (_) {}

    try {
      final parsed = DateFormat('HH:mm', 'en').parseStrict(value);
      return format(parsed, pattern: pattern);
    } catch (_) {}

    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) {
      return format(parsedIso, pattern: pattern);
    }

    return replaceAmPmWithArabic(value);
  }

  static String formatFromScheduledTimeField(
    String? rawTime, {
    String pattern = 'hh:mm a',
    String emptyValue = '-',
  }) {
    if (rawTime == null || rawTime.isEmpty) return emptyValue;
    final parsed = DateTime.tryParse('2000-01-01T$rawTime');
    if (parsed == null) return rawTime;
    return format(parsed, pattern: pattern);
  }

  static String formatDateTime(
    String? rawDateTime, {
    String pattern = 'yyyy-MM-dd hh:mm a',
    String emptyValue = '-',
  }) {
    if (rawDateTime == null || rawDateTime.trim().isEmpty) return emptyValue;
    final parsed = DateTime.tryParse(rawDateTime);
    if (parsed == null) return rawDateTime;
    return format(parsed.toLocal(), pattern: pattern);
  }
}
