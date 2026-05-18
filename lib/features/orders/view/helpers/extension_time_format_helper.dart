/// Arabic copy for extension duration in worker/customer UI.
String formatExtensionDurationAr(int? minutes) {
  final value = minutes ?? 0;
  if (value <= 0) {
    return 'وقت إضافي';
  }
  if (value % 60 == 0) {
    final hours = value ~/ 60;
    if (hours == 1) {
      return 'ساعة إضافية';
    }
    if (hours == 2) {
      return 'ساعتان إضافيتان';
    }
    return '$hours ساعات إضافية';
  }
  return '$value دقيقة إضافية';
}
