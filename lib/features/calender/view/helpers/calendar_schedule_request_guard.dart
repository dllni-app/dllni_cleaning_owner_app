/// Discards responses from obsolete calendar booking-schedule requests.
///
/// This does not grant session access or alter the selected-day fallback.
class CalendarScheduleRequestGuard {
  int _generation = 0;
  int? _bookingId;

  int begin(int bookingId) {
    _bookingId = bookingId;
    return ++_generation;
  }

  void invalidate() {
    _generation++;
    _bookingId = null;
  }

  bool isCurrent({required int generation, required int bookingId}) =>
      _generation == generation && _bookingId == bookingId;

  /// A scoped schedule is usable only when its returned parent matches the
  /// requested booking. Missing identity is not sufficient for this guard.
  bool acceptsResponse({
    required int generation,
    required int bookingId,
    required int? responseBookingId,
  }) =>
      responseBookingId == bookingId &&
      isCurrent(generation: generation, bookingId: bookingId);
}
