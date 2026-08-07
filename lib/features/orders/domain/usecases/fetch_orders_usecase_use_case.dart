import 'package:common_package/helpers/app_log.dart';
import 'package:common_package/helpers/typedef.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/cleaning_booking_status.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../repository/orders_repo.dart';

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
  static const String _acceptedWorkerStatuses =
      '${CleaningBookingStatus.workerAssigned},'
      '${CleaningBookingStatus.awaitingStartVerification},'
      '${CleaningBookingStatus.awaitingWorkerStartConfirmation},'
      '${CleaningBookingStatus.inProgress},'
      '${CleaningBookingStatus.awaitingCustomerCompletion},'
      '${CleaningBookingStatus.timeExtensionRequested},'
      '${CleaningBookingStatus.underDispute},'
      '${CleaningBookingStatus.completed}';

  final String? status;
  final String? scheduledDate;
  final String? scheduledDateFrom;
  final String? scheduledDateTo;
  final String? sort;
  final bool assignedToCurrentWorker;
  final bool acceptedByCurrentWorkerOnly;
  final int page;
  final int perPage;

  FetchOrdersUsecaseParams({
    this.status,
    this.scheduledDate,
    this.scheduledDateFrom,
    this.scheduledDateTo,
    this.sort,
    this.assignedToCurrentWorker = false,
    this.acceptedByCurrentWorkerOnly = false,
    required this.page,
    this.perPage = 10,
  });

  @override
  QueryParams getParams() {
    final effectiveStatus = acceptedByCurrentWorkerOnly
        ? _acceptedWorkerStatuses
        : status;
    final normalizedStatus = effectiveStatus?.trim().toLowerCase();
    final shouldFilterAssignedOrders =
        assignedToCurrentWorker &&
        normalizedStatus != CleaningBookingStatus.pending;

    final params = {
      'filter[forCurrentWorker]': 1,
      'filter[assignedToCurrentWorker]': shouldFilterAssignedOrders ? 1 : null,
      'filter[status]': effectiveStatus,
      'filter[scheduledDate]': scheduledDate,
      'filter[scheduledDateFrom]': scheduledDateFrom,
      'filter[scheduledDateTo]': scheduledDateTo,
      'perPage': '$perPage',
      'page': '$page',
      'sort': sort,
    }..removeWhere((key, value) => value == null);
    appLog(params.toString());
    return params;
  }
}
