import '../../data/models/cleaning_booking_operational_details.dart';

/// Presentation-only state for an Open-Time booking.
///
/// The elapsed value is anchored to timestamps issued by the server. It is not
/// used to submit, estimate, or finalize any financial value in the client.
class OpenTimePresentationState {
  const OpenTimePresentationState({
    required this.startedAt,
    required this.finishedAt,
    required this.elapsed,
    required this.isFinal,
  });

  final DateTime? startedAt;
  final DateTime? finishedAt;
  final Duration? elapsed;
  final bool isFinal;

  bool get hasStarted => startedAt != null;
}

class OrderOpenTimePresentation {
  const OrderOpenTimePresentation._();

  static OpenTimePresentationState resolve({
    required CleaningOpenTimeDetails? openTime,
    required DateTime now,
  }) {
    final startedAt = _parse(openTime?.workStartedAt);
    final finishedAt = _parse(openTime?.workFinishedAt);
    final serverDurationMinutes = openTime?.actualDurationMinutes;
    final isFinal = openTime?.isFinalized == true || finishedAt != null;

    if (isFinal &&
        serverDurationMinutes != null &&
        serverDurationMinutes >= 0) {
      return OpenTimePresentationState(
        startedAt: startedAt,
        finishedAt: finishedAt,
        elapsed: Duration(minutes: serverDurationMinutes),
        isFinal: isFinal,
      );
    }

    if (startedAt == null) {
      return OpenTimePresentationState(
        startedAt: null,
        finishedAt: finishedAt,
        elapsed: null,
        isFinal: isFinal,
      );
    }

    // A finalized server record without either a final timestamp or a final
    // duration is incomplete; do not let the local clock invent its duration.
    final endpoint = finishedAt ?? (isFinal ? null : now);
    if (endpoint == null) {
      return OpenTimePresentationState(
        startedAt: startedAt,
        finishedAt: null,
        elapsed: null,
        isFinal: true,
      );
    }
    final elapsed = endpoint.difference(startedAt);
    return OpenTimePresentationState(
      startedAt: startedAt,
      finishedAt: finishedAt,
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
      isFinal: isFinal,
    );
  }

  static DateTime? _parse(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
