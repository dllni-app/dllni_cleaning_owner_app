class EventAssistanceOrderHelper {
  EventAssistanceOrderHelper._();

  static const String propertyTypeValue = 'event_assistance';

  static String _normalize(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll('-', '_');
  }

  static bool isEventAssistance(String? propertyType) {
    return _normalize(propertyType) == propertyTypeValue;
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
    switch (_normalize(propertyType)) {
      case 'apartment':
      case 'flat':
      case 'شقة':
        return 'خدمة تنظيف شقة';
      case 'house':
      case 'home':
      case 'منزل':
        return 'خدمة تنظيف منزل';
      case 'office':
      case 'مكتب':
        return 'خدمة تنظيف مكتب';
      case 'villa':
      case 'فيلا':
        return 'خدمة تنظيف فيلا';
      case 'studio':
      case 'ستوديو':
      case 'استوديو':
        return 'خدمة تنظيف ستوديو';
      default:
        return propertyType?.trim().isNotEmpty == true
            ? 'خدمة تنظيف ${propertyType!.trim()}'
            : 'خدمة تنظيف';
    }
  }

  static String regularCleaningServiceName(String? propertyType) {
    switch (_normalize(propertyType)) {
      case 'apartment':
      case 'flat':
      case 'شقة':
        return 'تنظيف شقة';
      case 'house':
      case 'home':
      case 'منزل':
        return 'تنظيف منزل';
      case 'office':
      case 'مكتب':
        return 'تنظيف مكتب';
      case 'villa':
      case 'فيلا':
        return 'تنظيف فيلا';
      case 'studio':
      case 'ستوديو':
      case 'استوديو':
        return 'تنظيف ستوديو';
      default:
        return propertyType?.trim().isNotEmpty == true
            ? 'تنظيف ${propertyType!.trim()}'
            : 'تنظيف';
    }
  }

  static double? resolveBookedHours({
    double? propertyHours,
    double? assignmentHours,
    double? totalHours,
    double? estimatedHours,
  }) {
    // Worker-specific assignment/offer hours must win over the booking-wide
    // duration. The backend divides the order duration by the required worker
    // count before returning this value to the cleaning owner application.
    if (assignmentHours != null && assignmentHours > 0) return assignmentHours;
    if (totalHours != null && totalHours > 0) return totalHours;
    if (propertyHours != null && propertyHours > 0) return propertyHours;
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
    switch (_normalize(venueType)) {
      case 'apartment':
      case 'flat':
        return 'شقة';
      case 'villa':
        return 'فيلا';
      case 'house':
      case 'home':
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
    switch (_normalize(eventType)) {
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
