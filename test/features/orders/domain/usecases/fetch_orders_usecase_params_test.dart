import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FetchOrdersUsecaseParams', () {
    test('keeps pending orders visible even when assigned filter is requested', () {
      final params = FetchOrdersUsecaseParams(
        page: 1,
        status: CleaningBookingStatus.pending,
        assignedToCurrentWorker: true,
      ).getParams();

      expect(params['filter[forCurrentWorker]'], 1);
      expect(params['filter[status]'], CleaningBookingStatus.pending);
      expect(params.containsKey('filter[assignedToCurrentWorker]'), isFalse);
    });

    test('restricts non-pending statuses to assigned worker orders', () {
      final params = FetchOrdersUsecaseParams(
        page: 1,
        status: CleaningBookingStatus.workerAssigned,
        assignedToCurrentWorker: true,
      ).getParams();

      expect(params['filter[forCurrentWorker]'], 1);
      expect(params['filter[assignedToCurrentWorker]'], 1);
    });
  });
}
