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

  /// Short labels for week-strip cells (Mon…Sun).
  static const List<String> _arabicWeekdayShortNames = [
    'إثن',
    'ثلا',
    'أرب',
    'خمي',
    'جمع',
    'سبت',
    'أحد',
  ];

  /// Calendar months: January=1 … December=12.
  static const List<String> _arabicMonthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const String _westernDigits = '0123456789';
  static const String _easternDigits = '٠١٢٣٤٥٦٧٨٩';

  static String arabicWeekdayName(DateTime date) {
    return _arabicWeekdayNames[date.weekday - 1];
  }

  static String arabicWeekdayShortName(DateTime date) {
    return _arabicWeekdayShortNames[date.weekday - 1];
  }

  static String arabicMonthName(DateTime date) {
    return _arabicMonthNames[date.month - 1];
  }

  /// Converts Western digits in [input] to Eastern Arabic digits (display only).
  static String toArabicDigits(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final index = _westernDigits.indexOf(char);
      buffer.write(index >= 0 ? _easternDigits[index] : char);
    }
    return buffer.toString();
  }

  /// Day-of-month for calendar cells, e.g. `١٩`.
  static String formatCalendarDayNumber(DateTime date) {
    return toArabicDigits('${date.day}');
  }

  /// Week range header, e.g. `يوليو ١٩_٢٥`.
  static String formatCalendarWeekRange(
    DateTime focusedDay, {
    DateTime? startOfWeek,
    DateTime? endOfWeek,
  }) {
    final start = startOfWeek ??
        focusedDay.subtract(
          Duration(days: focusedDay.weekday % DateTime.daysPerWeek),
        );
    final end = endOfWeek ?? start.add(const Duration(days: 6));
    return toArabicDigits(
      '${arabicMonthName(focusedDay)} ${start.day}_${end.day}',
    );
  }

  /// Selected-date header, e.g. `١٩ يوليو ٢٠٢٦`.
  static String formatCalendarSelectedDate(DateTime date) {
    return toArabicDigits(
      '${date.day} ${arabicMonthName(date)} ${date.year}',
    );
  }

  /// Display-only `yyyy-MM-dd` with Eastern digits (API value stays Western).
  static String formatCalendarIsoDate(
    String? rawDate, {
    String emptyValue = '-',
  }) {
    if (rawDate == null || rawDate.trim().isEmpty) return emptyValue;
    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed == null) return toArabicDigits(rawDate.trim());
    final dateStr =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return toArabicDigits(dateStr);
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
