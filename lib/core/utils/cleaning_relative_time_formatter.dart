import 'package:intl/intl.dart';

import 'cleaning_date_time_parser.dart';

class CleaningRelativeTimeFormatter {
  const CleaningRelativeTimeFormatter._();

  static String fromBackendCreatedAt(dynamic createdAt) {
    final date = CleaningDateTimeParser.tryParseBackendUtc(createdAt);
    if (date == null) return '';
    return fromDateTime(date);
  }

  static String fromDateTime(DateTime date) {
    final now = DateTime.now();
    var diff = now.difference(date);

    if (diff.isNegative) {
      diff = Duration.zero;
    }

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes == 1) return 'منذ دقيقة';
    if (diff.inMinutes == 2) return 'منذ دقيقتين';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';

    if (diff.inHours == 1) return 'منذ ساعة';
    if (diff.inHours == 2) return 'منذ ساعتين';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';

    if (diff.inDays == 1) return 'منذ يوم';
    if (diff.inDays == 2) return 'منذ يومين';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';

    return DateFormat('dd/MM/yyyy').format(date);
  }
}
