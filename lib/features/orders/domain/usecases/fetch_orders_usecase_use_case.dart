import 'package:common_package/helpers/app_log.dart';
import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../repository/orders_repo.dart';
import '../../data/models/fetch_orders_usecase_model.dart';

@lazySingleton
class FetchOrdersUsecaseUseCase
    implements UseCase<FetchOrdersUsecaseModel, FetchOrdersUsecaseParams> {
  final OrdersRepo orders;

  FetchOrdersUsecaseUseCase({required this.orders});

  @override
  DataResponse<FetchOrdersUsecaseModel> call(FetchOrdersUsecaseParams params) {
    return orders.fetchOrdersUsecase(params);
  }
}

class FetchOrdersUsecaseParams with Params {
  final String? status;
  final String? scheduledDate;
  final String? scheduledDateFrom;
  final String? scheduledDateTo;
  final String? sort;
  final bool assignedToCurrentWorker;
  final int page;
  final int perPage;

  FetchOrdersUsecaseParams({
    this.status,
    this.scheduledDate,
    this.scheduledDateFrom,
    this.scheduledDateTo,
    this.sort,
    this.assignedToCurrentWorker = false,
    required this.page,
    this.perPage = 10,
  });

  @override
  QueryParams getParams() {
    final params = {
      "filter[forCurrentWorker]": 1,
      "filter[assignedToCurrentWorker]": assignedToCurrentWorker ? 1 : null,
      "filter[status]": status,
      "filter[scheduledDate]": scheduledDate,
      "filter[scheduledDateFrom]": scheduledDateFrom,
      "filter[scheduledDateTo]": scheduledDateTo,
      "perPage": "$perPage",
      "page": "$page",
      "sort": sort,
    }..removeWhere((key, value) => value == null);
    appLog(params.toString());
    return params;
  }
}
