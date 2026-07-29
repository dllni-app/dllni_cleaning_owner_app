import 'dart:convert';

import 'package:common_package/helpers/shared_preferences_helper.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_global_prompt_coordinator.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const currentWorkerId = 99;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user': jsonEncode({
        'data': {'id': currentWorkerId},
      }),
    });
    await SharedPreferencesHelper.init();
  });

  test('findPendingBookingIds keeps dedicated pending orders only', () {
    final orders = <FetchOrdersUsecaseModelDataItem>[
      FetchOrdersUsecaseModelDataItem(
        id: 1,
        status: CleaningBookingStatus.pending,
        preferredWorkerId: currentWorkerId,
      ),
      FetchOrdersUsecaseModelDataItem(
        id: 2,
        status: CleaningBookingStatus.inProgress,
        preferredWorkerId: currentWorkerId,
      ),
      FetchOrdersUsecaseModelDataItem(
        id: 3,
        status: CleaningBookingStatus.pending,
        preferredWorkerId: 55,
      ),
      FetchOrdersUsecaseModelDataItem(
        id: 4,
        status: CleaningBookingStatus.pending,
      ),
    ];
    expect(
      CleaningWorkerGlobalPromptCoordinator.findPendingBookingIds(orders),
      <int>[1],
    );
  });
}
