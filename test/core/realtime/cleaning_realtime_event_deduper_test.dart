import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_event_deduper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drops duplicate realtime event keys', () {
    final deduper = CleaningRealtimeEventDeduper();
    final payload = <String, dynamic>{
      'cleaningBookingId': 10,
      'warningId': 99,
      'decision': 'extension_requested',
      'version': 1,
    };

    expect(deduper.shouldProcess('ServiceExtensionRequested', payload), isTrue);
    expect(deduper.shouldProcess('ServiceExtensionRequested', payload), isFalse);
  });

  test('allows new event when discriminator changes', () {
    final deduper = CleaningRealtimeEventDeduper();
    expect(
      deduper.shouldProcess('CompletionDecisionMade', <String, dynamic>{
        'cleaningBookingId': 10,
        'decision': 'approved',
        'decidedAt': '2026-07-01T10:00:00Z',
      }),
      isTrue,
    );
    expect(
      deduper.shouldProcess('CompletionDecisionMade', <String, dynamic>{
        'cleaningBookingId': 10,
        'decision': 'approved',
        'decidedAt': '2026-07-01T10:01:00Z',
      }),
      isTrue,
    );
  });
}
