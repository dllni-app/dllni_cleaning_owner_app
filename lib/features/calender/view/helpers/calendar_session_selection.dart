import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';

/// Returns only sessions that belong to the date currently shown by the
/// calendar. The schedule fallback is reserved for callers without a date
/// filter; it must not substitute another day's session into a filtered view.
List<WorkerBookingSessionModel> selectCalendarSessionsForDate({
  required WorkerBookingScheduleModel schedule,
  required String? selectedDate,
}) {
  if (!schedule.isMultiDay) return const <WorkerBookingSessionModel>[];

  final requestedDate = selectedDate?.trim();
  if (requestedDate != null && requestedDate.isNotEmpty) {
    return schedule.sessions
        .where((session) => calendarDateKey(session.date) == requestedDate)
        .toList(growable: false);
  }

  final next = schedule.nextSession;
  if (next != null) {
    for (final session in schedule.sessions) {
      if (session.id == next.id) {
        return <WorkerBookingSessionModel>[session];
      }
    }
    return <WorkerBookingSessionModel>[next];
  }
  if (schedule.sessions.isEmpty) {
    return const <WorkerBookingSessionModel>[];
  }
  return <WorkerBookingSessionModel>[schedule.sessions.first];
}

String calendarDateKey(DateTime? date) {
  if (date == null) return '';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
