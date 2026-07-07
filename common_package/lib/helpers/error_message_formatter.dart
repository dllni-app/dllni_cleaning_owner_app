import 'package:easy_localization/easy_localization.dart';

class ErrorMessageFormatter {
  ErrorMessageFormatter._();

  static const String defaultFallback = 'حدث خطأ. حاول مرة أخرى.';

  static String format(
    String? message, {
    String fallback = defaultFallback,
  }) {
    final raw = message?.trim();
    if (raw == null || raw.isEmpty) return fallback;

    if (_looksLikeLocaleKey(raw)) {
      final translated = raw.tr();
      if (translated != raw) return translated;
      return fallback;
    }

    return raw;
  }

  static bool _looksLikeLocaleKey(String value) {
    return value.startsWith('errorMessage.') || value.startsWith('validation.');
  }
}
