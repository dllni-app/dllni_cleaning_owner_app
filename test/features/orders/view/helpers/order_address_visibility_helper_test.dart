import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_address_visibility_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visibleOrderAddress', () {
    test('hides pending order address after the first comma', () {
      expect(
        visibleOrderAddress(
          address: 'العزيزية, شارع الكتاب المقدس, جانب محل مميز, 2b',
          status: CleaningBookingStatus.pending,
        ),
        'العزيزية',
      );
    });

    test('hides pending order address after the first Arabic comma', () {
      expect(
        visibleOrderAddress(
          address: 'العزيزية، شارع الكتاب المقدس، جانب محل مميز 2b',
          status: CleaningBookingStatus.pending,
        ),
        'العزيزية',
      );
    });

    test('uses address value for pending order instead of location name', () {
      expect(
        visibleOrderAddress(
          address: 'العزيزية، شارع الكتاب المقدس، جانب محل مميز 2b',
          status: CleaningBookingStatus.pending,
        ),
        'العزيزية',
      );
    });

    test('treats pending-like statuses as pending', () {
      expect(
        visibleOrderAddress(
          address: 'العزيزية، شارع الكتاب المقدس، جانب محل مميز 2b',
          status: 'pending_worker_acceptance',
        ),
        'العزيزية',
      );
    });

    test('keeps full address for non-pending orders', () {
      const address = 'العزيزية, شارع الكتاب المقدس, جانب محل مميز, 2b';

      expect(
        visibleOrderAddress(
          address: address,
          status: CleaningBookingStatus.workerAssigned,
        ),
        address,
      );
    });

    test('returns dash for missing address', () {
      expect(
        visibleOrderAddress(
          address: ' ',
          status: CleaningBookingStatus.pending,
        ),
        '-',
      );
    });
  });
}
