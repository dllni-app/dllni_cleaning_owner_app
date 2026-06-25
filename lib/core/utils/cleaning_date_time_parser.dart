class CleaningDateTimeParser {
  const CleaningDateTimeParser._();

  static DateTime? tryParseBackendUtc(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    try {
      final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);

      if (hasTimezone) {
        return DateTime.parse(raw).toLocal();
      }

      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      return DateTime.parse('${normalized}Z').toLocal();
    } catch (_) {
      return null;
    }
  }
}
