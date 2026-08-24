import 'package:dllni_cleaninig_owner_app/features/profile/data/models/notification_api_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters unavailable new-order notifications from the parsed feed', () {
    final page = fetchNotificationsPageModelFromJson({
      'data': [
        {
          'id': 'hidden-by-state',
          'type': 'new_order',
          'canonicalType': 'cleaning.booking.new_order_request',
          'data': {'bookingId': 10, 'state': 'unavailable'},
        },
        {
          'id': 'hidden-by-actionable',
          'type': 'new_order',
          'data': {'bookingId': 11, 'actionable': false},
        },
        {
          'id': 'hidden-by-string-actionable',
          'canonicalType': 'cleaning.booking.new_order_request',
          'data': {'bookingId': 12, 'actionable': 'false'},
        },
        {
          'id': 'visible-new-order',
          'type': 'new_order',
          'data': {'bookingId': 13},
        },
        {
          'id': 'visible-non-order',
          'type': 'extension_request',
          'data': {'bookingId': 14, 'actionable': false},
        },
      ],
      'countUnread': 2,
      'meta': {
        'current_page': 1,
        'per_page': 10,
        'total': 5,
      },
    });

    expect(
      page.data?.map((notification) => notification.id).toList(),
      ['visible-new-order', 'visible-non-order'],
    );
  });
}
