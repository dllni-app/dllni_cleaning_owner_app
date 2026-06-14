import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/sos_alert_models.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/create_cleaning_booking_sos_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/event_assistance_order_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventAssistanceOrderHelper', () {
    test('uses custom service title for event assistance', () {
      expect(
        EventAssistanceOrderHelper.serviceTitle(
          propertyType: 'event_assistance',
          customService: 'Serving and cleanup support',
        ),
        'Serving and cleanup support',
      );
    });

    test('formats fractional booked hours', () {
      expect(EventAssistanceOrderHelper.formatHours(2.5), '2.5 ساعة');
      expect(EventAssistanceOrderHelper.formatHours(4), '4 ساعة');
    });
  });

  group('PropertyDetailsData event parsing', () {
    test('parses snake_case and camelCase event fields', () {
      final snake = PropertyDetailsData.fromJson(<String, dynamic>{
        'custom_service': 'Manual hospitality support',
        'guest_count': 40,
        'venue_type': 'apartment',
        'hours': 5,
      });
      final camel = PropertyDetailsData.fromJson(<String, dynamic>{
        'customService': 'Setup support',
        'guestCount': 12,
        'venueType': 'villa',
        'hours': 2.5,
      });

      expect(snake.customService, 'Manual hospitality support');
      expect(snake.guestCount, 40);
      expect(camel.customService, 'Setup support');
      expect(camel.hours, 2.5);
    });
  });

  group('SosAlertModel', () {
    test('builds worker SOS body with contract field names', () {
      final body = CreateCleaningBookingSosParams(
        bookingId: 101,
        emergencyType: 'severe_conflict',
        message: '  Need urgent help  ',
        latitude: 33.5138,
        longitude: 36.2765,
      ).getBody();

      expect(body, <String, dynamic>{
        'emergency_type': 'severe_conflict',
        'message': 'Need urgent help',
        'lat': 33.5138,
        'lng': 36.2765,
      });
    });

    test('parses list timestamp and dynamic booking map', () {
      final alert = SosAlertModel.fromJson(<String, dynamic>{
        'id': 7,
        'created_at': '2026-06-11 20:15:30',
        'booking': <String, dynamic>{
          'id': 101,
          'propertyType': 'event_assistance',
        },
      });

      expect(alert.id, 7);
      expect(alert.createdAt, isNotNull);
      expect(alert.booking?['propertyType'], 'event_assistance');
    });
  });
}
