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
      return _safeArabicFallback(fallback);
    }

    final knownArabicMessage = _knownBackendMessage(raw.toLowerCase());
    if (knownArabicMessage != null) return knownArabicMessage;

    // Backend and transport libraries can return English/technical text directly.
    // Never expose predominantly English errors to the worker application.
    if (_isPredominantlyEnglish(raw)) {
      return _safeArabicFallback(fallback);
    }

    return raw;
  }

  static String? _knownBackendMessage(String value) {
    if (value.contains("outside the worker's active neighborhoods") ||
        value.contains('outside the worker active neighborhoods') ||
        value.contains('outside your active neighborhoods')) {
      return 'هذا الطلب خارج الأحياء النشطة المحددة ضمن مناطق عملك.';
    }

    if (value.contains('overlaps another confirmed booking') ||
        (value.contains('schedule') && value.contains('overlap'))) {
      return 'لا يمكن تنفيذ العملية لأن موعد هذا الطلب يتعارض مع حجز مؤكد آخر في جدولك.';
    }

    if ((value.contains('commission') || value.contains('deposit')) &&
        (value.contains('does not cover') ||
            value.contains('insufficient') ||
            value.contains('allowance'))) {
      return 'لا يمكن تنفيذ العملية حالياً لأن رصيد التأمين أو حد السماح لا يغطي متطلبات هذا الطلب.';
    }

    if (value.contains('worker home location is required')) {
      return 'يرجى استكمال عنوان وموقع منزل العامل قبل تنفيذ هذه العملية.';
    }

    if (value.contains('customer location coordinates are required')) {
      return 'تعذر تنفيذ العملية لأن عنوان العميل لا يحتوي على موقع صحيح على الخريطة.';
    }

    if (value.contains('gender preference does not match')) {
      return 'لا يمكن قبول الطلب لأن تفضيل جنس العامل لا يطابق بيانات حسابك.';
    }

    if (value.contains('reserved for a different preferred worker')) {
      return 'هذا الطلب محجوز لعامل مفضل آخر.';
    }

    if (value.contains('required number of workers')) {
      return 'اكتمل عدد العمال المطلوب لهذا الطلب ولم يعد متاحاً للقبول.';
    }

    if (value.contains('cannot be accepted in current status')) {
      return 'لا يمكن قبول الطلب في حالته الحالية.';
    }

    if (value.contains('assigned to another worker')) {
      return 'هذا الطلب مسند إلى عامل آخر.';
    }

    if (value.contains('must have an associated worker')) {
      return 'تعذر تنفيذ العملية لأن حسابك غير مرتبط بملف عامل صالح.';
    }

    if (value.contains('must be assigned to worker for this action')) {
      return 'لا يمكن تنفيذ هذه العملية قبل إسناد الطلب إلى العامل.';
    }

    if (value.contains('security code is only available')) {
      return 'رمز التحقق متاح فقط عندما يكون الطلب جاهزاً للبدء.';
    }

    if (value.contains('cannot create an sos request') &&
        (value.contains('completed') || value.contains('cancelled'))) {
      return 'لا يمكن إرسال طلب استغاثة لطلب مكتمل أو ملغى.';
    }

    if (value.contains('sos request already exists') ||
        value.contains('already exists') && value.contains('sos')) {
      return 'تم إرسال طلب الاستغاثة مسبقاً وهو قيد المتابعة.';
    }

    if (value.contains('cannot start travel in current status')) {
      return 'لا يمكن بدء التوجه إلى موقع الطلب في حالته الحالية.';
    }

    if (value.contains('outside the allowed') &&
        value.contains('travel')) {
      return 'لا يمكن بدء التوجه الآن لأن الموعد خارج الفترة المسموحة.';
    }

    if (value.contains('not found')) {
      return 'العنصر المطلوب غير موجود أو لم يعد متاحاً.';
    }

    if (value.contains('unauthenticated') ||
        value.contains('authentication required')) {
      return 'انتهت الجلسة أو يلزم تسجيل الدخول مرة أخرى.';
    }

    if (value.contains('forbidden') ||
        value.contains('not authorized') ||
        value.contains('not allowed')) {
      return 'غير مسموح بتنفيذ هذه العملية.';
    }

    if (value.contains('too many requests') ||
        value.contains('too many attempts')) {
      return 'تم إرسال طلبات كثيرة خلال وقت قصير. حاول مرة أخرى بعد قليل.';
    }

    if (value.contains('timeout') ||
        value.contains('timed out') ||
        value.contains('connection error') ||
        value.contains('network error')) {
      return 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
    }

    if (value.contains('status code of 422') ||
        value.contains('requestoptions.validatestatus') ||
        value.contains('dioexception')) {
      return 'تعذر تنفيذ العملية بسبب بيانات أو شروط غير صالحة. تحقق من البيانات ثم حاول مرة أخرى.';
    }

    return null;
  }

  static String _safeArabicFallback(String fallback) {
    final value = fallback.trim();
    if (value.isNotEmpty && _arabicLetterCount(value) > 0) return value;
    return defaultFallback;
  }

  static bool _isPredominantlyEnglish(String value) {
    final latin = _latinLetterCount(value);
    if (latin == 0) return false;

    final arabic = _arabicLetterCount(value);
    return arabic == 0 || latin > arabic;
  }

  static int _latinLetterCount(String value) {
    return RegExp(r'[A-Za-z]').allMatches(value).length;
  }

  static int _arabicLetterCount(String value) {
    return RegExp(r'[\u0600-\u06FF]').allMatches(value).length;
  }

  static bool _looksLikeLocaleKey(String value) {
    return value.startsWith('errorMessage.') ||
        value.startsWith('validation.');
  }
}
