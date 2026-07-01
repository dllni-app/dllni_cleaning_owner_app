import 'cleaning_realtime_contract.dart';

class CleaningRealtimeEventDeduper {
  CleaningRealtimeEventDeduper({this.maxKeys = 250});

  final int maxKeys;
  final Set<String> _seenKeys = <String>{};

  bool shouldProcess(String eventName, Map<String, dynamic> payload) {
    final unwrapped = CleaningRealtimeContract.unwrapPayload(payload);
    final bookingId = CleaningRealtimeContract.extractBookingId(unwrapped);
    final warningId = CleaningRealtimeContract.extractWarningId(unwrapped);
    final key = <Object?>[
      CleaningRealtimeContract.normalizeEventName(eventName),
      bookingId,
      warningId,
      unwrapped['decision'],
      unwrapped['status'] ?? unwrapped['orderStatus'],
      unwrapped['version'],
      unwrapped['decidedAt'] ?? unwrapped['decided_at'] ?? unwrapped['updatedAt'] ?? unwrapped['updated_at'],
    ].join('|');

    if (_seenKeys.contains(key)) return false;
    _seenKeys.add(key);
    if (_seenKeys.length > maxKeys) {
      _seenKeys.remove(_seenKeys.first);
    }
    return true;
  }

  void clear() => _seenKeys.clear();
}
