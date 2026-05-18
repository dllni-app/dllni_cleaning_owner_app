import '../../../data/models/cleaning_booking_status.dart';

/// Live location is only sent while the worker is en route to the customer.
/// Stops once they tap arrive / backend records arrival / verification starts.
bool shouldReportWorkerLocation({
  required String? status,
  required String? startedTravelAt,
  String? arrivedAt,
}) {
  final normalizedStatus = (status ?? '').toLowerCase();
  if (normalizedStatus != CleaningBookingStatus.workerAssigned) {
    return false;
  }
  if ((startedTravelAt ?? '').trim().isEmpty) {
    return false;
  }
  if ((arrivedAt ?? '').trim().isNotEmpty) {
    return false;
  }
  return true;
}
