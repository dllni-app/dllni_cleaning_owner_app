import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_schedule_change_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses pending worker schedule-change requests', () {
    final changes = cleaningScheduleChangeRequestsEnvelopeFromJson(
      <String, dynamic>{
        'data': <String, dynamic>{
          'changeRequests': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 14,
              'cleaning_booking_id': 71,
              'status': 'pending',
              'price_delta': '500',
              'proposed_snapshot': <String, dynamic>{
                'sessions': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'date': '2026-09-21',
                    'time': '09:15',
                    'hours': 3,
                  },
                ],
              },
            },
          ],
        },
      },
    );

    expect(changes, hasLength(1));
    expect(changes.single.id, 14);
    expect(changes.single.bookingId, 71);
    expect(changes.single.priceDelta, 500);
    expect(changes.single.sessions.single.time, '09:15');
  });

  test('parses a decision response envelope', () {
    final change = cleaningScheduleChangeRequestEnvelopeFromJson(
      <String, dynamic>{
        'data': <String, dynamic>{
          'changeRequest': <String, dynamic>{
            'id': 14,
            'booking': <String, dynamic>{'id': 71},
            'status': 'applied',
            'priceDelta': 0,
          },
        },
      },
    );

    expect(change.bookingId, 71);
    expect(change.status, 'applied');
  });
}
