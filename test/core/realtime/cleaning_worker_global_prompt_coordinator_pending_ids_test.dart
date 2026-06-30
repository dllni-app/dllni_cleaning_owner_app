import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_global_prompt_coordinator.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('findPendingBookingIds keeps pending orders only', () {
    final orders = <FetchOrdersUsecaseModelDataItem>[
      FetchOrdersUsecaseModelDataItem(id: 1, status: CleaningBookingStatus.pending),
      FetchOrdersUsecaseModelDataItem(id: 2, status: CleaningBookingStatus.inProgress),
    ];
    expect(CleaningWorkerGlobalPromptCoordinator.findPendingBookingIds(orders), <int>[1]);
  });
}
