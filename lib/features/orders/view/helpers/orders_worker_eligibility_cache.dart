import 'dart:convert';

import 'package:common_package/common_package.dart';

import '../../data/models/fetch_orders_usecase_model.dart';

class OrdersWorkerEligibilityCache {
  const OrdersWorkerEligibilityCache._();

  static void saveFromOrdersResponse(FetchOrdersUsecaseModel model) {
    final eligibility = model.dispatchEligibility;
    if (eligibility == null) return;

    SharedPreferencesHelper.saveData(
      key: 'worker_dispatch_eligibility',
      value: jsonEncode(eligibility.toJson()),
    );
    SharedPreferencesHelper.saveData(
      key: 'worker_can_receive_new_requests',
      value: eligibility.canReceiveNewRequests == true,
    );
    SharedPreferencesHelper.saveData(
      key: 'worker_eligibility_message_ar',
      value: eligibility.userMessageAr,
    );
  }
}
