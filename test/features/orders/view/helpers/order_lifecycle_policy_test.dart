import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

FetchOrdersUsecaseModelDataItem _order({
  String? status,
  String? startedTravelAt,
  String? bookingNumber,
}) {
  return FetchOrdersUsecaseModelDataItem(
    id: 1,
    status: status,
    startedTravelAt: startedTravelAt,
    bookingNumber: bookingNumber ?? 'CLN-1',
  );
}

void main() {
  group('OrderLifecyclePolicy', () {
    test('pending allows accept reject only', () {
      final order = _order(status: CleaningBookingStatus.pending);
      expect(OrderLifecyclePolicy.canAcceptReject(order), isTrue);
      expect(OrderLifecyclePolicy.canStartTravel(order), isFalse);
      expect(OrderLifecyclePolicy.detailsStepFor(order), 0);
    });

    test('assigned without travel allows start travel and cancel', () {
      final order = _order(status: CleaningBookingStatus.workerAssigned);
      expect(OrderLifecyclePolicy.canStartTravel(order), isTrue);
      expect(OrderLifecyclePolicy.canCancel(order), isTrue);
      expect(OrderLifecyclePolicy.detailsStepFor(order), 1);
    });

    test('traveling allows arrive on map step', () {
      final order = _order(
        status: CleaningBookingStatus.workerAssigned,
        startedTravelAt: '2026-05-18T10:00:00Z',
      );
      expect(OrderLifecyclePolicy.canArrive(order), isTrue);
      expect(OrderLifecyclePolicy.detailsStepFor(order), 2);
    });

    test('in progress allows complete', () {
      expect(
        OrderLifecyclePolicy.canCompleteWork(CleaningBookingStatus.inProgress),
        isTrue,
      );
      expect(
        OrderLifecyclePolicy.isAwaitingCustomerCompletion(
          CleaningBookingStatus.awaitingCustomerCompletion,
        ),
        isTrue,
      );
    });

    test('does not downgrade from in_progress to awaiting verification', () {
      expect(
        OrderLifecyclePolicy.shouldPreferIncomingStatus(
          CleaningBookingStatus.inProgress,
          CleaningBookingStatus.awaitingStartVerification,
        ),
        isFalse,
      );
      expect(
        OrderLifecyclePolicy.shouldPreferIncomingStatus(
          CleaningBookingStatus.awaitingStartVerification,
          CleaningBookingStatus.inProgress,
        ),
        isTrue,
      );
      expect(
        OrderLifecyclePolicy.detailsStepForStatus(
          CleaningBookingStatus.inProgress,
        ),
        3,
      );
    });
  });
}
