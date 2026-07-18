class CleaningEnumTranslations {
  static String valueOrFallback(String? value, {String fallback = 'غير محدد'}) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  static bool isArabicLabel(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return false;
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  static String preferArabicLabel(
    String? backendLabel,
    String? rawValue,
    String Function(String?) translator, {
    String fallback = 'غير محدد',
  }) {
    if (isArabicLabel(backendLabel)) return backendLabel!.trim();
    final translated = translator(rawValue ?? backendLabel);
    if (translated.trim().isNotEmpty && translated != rawValue) return translated;
    return valueOrFallback(rawValue ?? backendLabel, fallback: fallback);
  }

  static String bookingStatus(String? value) {
    switch (_normalize(value)) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted_waiting_for_order_start':
        return 'تم القبول بانتظار بدء الطلب';
      case 'accepted_waiting_team':
        return 'تم القبول بانتظار اكتمال الفريق';
      case 'worker_assigned':
        return 'تم تعيين العامل';
      case 'awaiting_start_verification':
        return 'بانتظار تأكيد بدء العمل';
      case 'awaiting_worker_start_confirmation':
        return 'بانتظار بدء العمل من العامل';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'awaiting_customer_completion':
        return 'بانتظار تأكيد العميل للإنهاء';
      case 'time_extension_requested':
        return 'تم طلب تمديد الوقت';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      case 'withdrawn':
        return 'منسحب';
      default:
        return valueOrFallback(value);
    }
  }

  static String propertyType(String? value) {
    switch (_normalize(value)) {
      case 'apartment':
        return 'شقة';
      case 'villa':
        return 'فيلا';
      case 'house':
      case 'home':
        return 'منزل';
      case 'office':
        return 'مكتب';
      case 'studio':
        return 'استوديو';
      case 'event_assistance':
        return 'مساعدة مناسبة';
      default:
        return valueOrFallback(value);
    }
  }

  static String livingRoomSize(String? value) => roomSize(value);

  static String roomSize(String? value) {
    switch (_normalize(value)) {
      case 'small':
        return 'صغيرة';
      case 'medium':
        return 'متوسطة';
      case 'large':
        return 'كبيرة';
      case 'none':
        return 'لا يوجد';
      default:
        return valueOrFallback(value);
    }
  }

  static String roomType(String? value) {
    switch (_normalize(value)) {
      case 'bedroom':
      case 'bed room':
        return 'غرفة نوم';
      case 'bathroom':
      case 'bath room':
        return 'حمام';
      case 'living_room':
      case 'living room':
        return 'غرفة معيشة';
      case 'kitchen':
        return 'مطبخ';
      case 'balcony':
        return 'شرفة';
      case 'hall':
        return 'صالة';
      case 'corridor':
        return 'ممر';
      case 'shed':
        return 'سقيفة';
      case 'toilet':
        return 'حمام صغير';
      default:
        return valueOrFallback(value, fallback: 'غرفة');
    }
  }

  static String cleaningMode(String? value) {
    switch (_normalize(value)) {
      case 'regular':
        return 'تنظيف عادي';
      case 'deep':
        return 'تنظيف عميق';
      default:
        return valueOrFallback(value);
    }
  }

  static String eventType(String? value) {
    switch (_normalize(value)) {
      case 'family_dinner':
        return 'عشاء عائلي';
      case 'birthday':
        return 'عيد ميلاد';
      case 'large_gathering':
        return 'تجمع كبير';
      case 'funeral':
        return 'عزاء';
      case 'other':
        return 'أخرى';
      default:
        return valueOrFallback(value);
    }
  }

  static String venueType(String? value) {
    switch (_normalize(value)) {
      case 'apartment':
      case 'flat':
      case 'شقة':
        return 'شقة';
      case 'villa':
      case 'فيلا':
        return 'فيلا';
      case 'house':
      case 'home':
      case 'منزل':
        return 'منزل';
      case 'hall':
      case 'قاعة':
        return 'قاعة';
      case 'outdoor':
      case 'خارجي':
        return 'خارجي';
      case 'office':
      case 'مكتب':
        return 'مكتب';
      case 'studio':
      case 'ستوديو':
      case 'استوديو':
        return 'استوديو';
      case 'other':
      case 'أخرى':
        return 'أخرى';
      default:
        return valueOrFallback(value);
    }
  }

  static String _normalize(String? value) {
    return value?.trim().toLowerCase().replaceAll('-', '_') ?? '';
  }
}
