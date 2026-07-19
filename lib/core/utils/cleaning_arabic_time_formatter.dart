import 'package:intl/intl.dart';

class CleaningArabicTimeFormatter {
  const CleaningArabicTimeFormatter._();

  /// Dart [DateTime.weekday]: Monday=1 … Sunday=7.
  static const List<String> _arabicWeekdayNames = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static String arabicWeekdayName(DateTime date) {
    return _arabicWeekdayNames[date.weekday - 1];
  }

  static String formatScheduledWeekday(
    String? rawDate, {
    String emptyValue = '-',
  }) {
    if (rawDate == null || rawDate.trim().isEmpty) return emptyValue;
    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed == null) return emptyValue;
    return arabicWeekdayName(parsed);
  }

  static String formatScheduledDate(
    String? rawDate, {
    String emptyValue = '-',
    bool includeWeekday = true,
    String pattern = 'yyyy-MM-dd',
  }) {
    if (rawDate == null || rawDate.trim().isEmpty) return emptyValue;
    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed == null) return rawDate;
    final dateStr =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    // Keep DateFormat for custom patterns when weekday is inlined elsewhere.
    final formatted = pattern == 'yyyy-MM-dd'
        ? dateStr
        : DateFormat(pattern, 'en').format(parsed);
    if (!includeWeekday) return formatted;
    return '${arabicWeekdayName(parsed)} $formatted';
  }

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
