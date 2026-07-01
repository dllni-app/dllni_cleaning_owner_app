import 'package:common_package/common_package.dart';

import '../../data/models/fetch_orders_usecase_model.dart';

class OrdersPendingOrderListHydrator {
  const OrdersPendingOrderListHydrator._();

  static PaginationStateModel<FetchOrdersUsecaseModelDataItem> upsert(
    PaginationStateModel<FetchOrdersUsecaseModelDataItem> pagination,
    FetchOrdersUsecaseModelDataItem item,
  ) {
    final updated = List<FetchOrdersUsecaseModelDataItem>.of(pagination.list);
    final index = updated.indexWhere((order) => order.id == item.id);
    if (index >= 0) {
      updated[index] = item;
    } else {
      updated.insert(0, item);
    }

    return pagination.copyWith(
      list: updated,
      status: BlocStatus.success,
    );
  }
}
