class EventAssistanceOrderHelper {
  EventAssistanceOrderHelper._();

  static const String propertyTypeValue = 'event_assistance';

  static bool isEventAssistance(String? propertyType) {
    return (propertyType ?? '').trim().toLowerCase() == propertyTypeValue;
  }

  static String serviceTitle({
    required String? propertyType,
    String? customService,
  }) {
    if (isEventAssistance(propertyType)) {
      final task = customService?.trim();
      if (task != null && task.isNotEmpty) {
        return task;
      }
      return 'مساعدة مناسبة';
    }
    return regularCleaningServiceTitle(propertyType);
  }

  static String regularCleaningServiceTitle(String? propertyType) {
    switch ((propertyType ?? '').toLowerCase()) {
      case 'apartment':
        return 'خدمة تنظيف شقة';
      case 'house':
        return 'خدمة تنظيف منزل';
      case 'villa':
        return 'خدمة تنظيف فيلا';
      case 'studio':
        return 'خدمة تنظيف ستوديو';
      default:
        return 'خدمة تنظيف منزل';
    }
  }

  static String regularCleaningServiceName(String? propertyType) {
    switch ((propertyType ?? '').toLowerCase()) {
      case 'apartment':
        return 'تنظيف شقة';
      case 'house':
        return 'تنظيف منزل';
      case 'villa':
        return 'تنظيف فيلا';
      case 'studio':
        return 'تنظيف ستوديو';
      default:
        return 'تنظيف منزل';
    }
  }

  static double? resolveBookedHours({
    double? propertyHours,
    double? totalHours,
    double? estimatedHours,
  }) {
    if (propertyHours != null && propertyHours > 0) return propertyHours;
    if (totalHours != null && totalHours > 0) return totalHours;
    if (estimatedHours != null && estimatedHours > 0) return estimatedHours;
    return null;
  }

  static String formatHours(double? hours) {
    if (hours == null) return '-';
    final normalized = hours % 1 == 0 ? hours.toInt().toString() : hours.toString();
    return '$normalized ساعة';
  }

  static String formatHoursDetail(double? hours) {
    if (hours == null) return '-';
    final normalized = hours % 1 == 0 ? hours.toInt().toString() : hours.toString();
    return '$normalized ساعات';
  }

  static String venueTypeLabelAr(String? venueType) {
    switch ((venueType ?? '').toLowerCase()) {
      case 'apartment':
        return 'شقة';
      case 'villa':
        return 'فيلا';
      case 'house':
        return 'منزل';
      case 'office':
        return 'مكتب';
      case 'studio':
        return 'ستوديو';
      default:
        return venueType?.trim().isNotEmpty == true ? venueType!.trim() : '-';
    }
  }

  static String eventTypeLabelAr(String? eventType) {
    switch ((eventType ?? '').toLowerCase()) {
      case 'family_dinner':
        return 'عشاء عائلي';
      case 'birthday':
        return 'عيد ميلاد';
      case 'large_gathering':
        return 'تجمع كبير';
      case 'funeral':
        return 'عزاء';
      case 'other':
        return 'مناسبة أخرى';
      default:
        return eventType?.trim().isNotEmpty == true ? eventType!.trim() : '-';
    }
  }
}
