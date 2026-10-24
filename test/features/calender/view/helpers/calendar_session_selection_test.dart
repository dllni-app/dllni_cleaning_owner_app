import 'package:dllni_cleaninig_owner_app/features/calender/view/helpers/calendar_session_selection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final firstDay = _session(id: 11, sequence: 1, date: DateTime(2026, 10, 24));
  final secondDay = _session(id: 12, sequence: 2, date: DateTime(2026, 10, 25));
  final schedule = _schedule(
    sessions: [firstDay, secondDay],
    nextSession: secondDay,
  );

  test('returns every session scheduled on the selected date', () {
    expect(
      selectCalendarSessionsForDate(
        schedule: schedule,
        selectedDate: '2026-10-24',
      ),
      [firstDay],
    );
  });

  test('does not substitute next session when selected day has no visit', () {
    expect(
      selectCalendarSessionsForDate(
        schedule: schedule,
        selectedDate: '2026-10-26',
      ),
      isEmpty,
    );
  });

  test('does not substitute a session when selected day is malformed', () {
    expect(
      selectCalendarSessionsForDate(
        schedule: schedule,
        selectedDate: 'not-a-date',
      ),
      isEmpty,
    );
  });

  test('uses the authoritative next session only without a date filter', () {
    expect(
      selectCalendarSessionsForDate(schedule: schedule, selectedDate: null),
      [secondDay],
    );
  });
}

WorkerBookingScheduleModel _schedule({
  required List<WorkerBookingSessionModel> sessions,
  required WorkerBookingSessionModel? nextSession,
}) => WorkerBookingScheduleModel(
  mode: 'multi_day',
  daysCount: sessions.length,
  completedDaysCount: 0,
  cancelledDaysCount: 0,
  remainingDaysCount: sessions.length,
  totalHours: sessions.fold<double>(
    0,
    (total, session) => total + session.hours,
  ),
  sessions: sessions,
  nextSession: nextSession,
);

WorkerBookingSessionModel _session({
  required int id,
  required int sequence,
  required DateTime date,
}) => WorkerBookingSessionModel(
  id: id,
  sequence: sequence,
  date: date,
  hours: 2,
  status: 'scheduled',
  isToday: false,
  isPast: false,
  canStartTravel: false,
  canArrive: false,
  canStartWork: false,
  canComplete: false,
  canExtend: false,
  canCancel: false,
);
