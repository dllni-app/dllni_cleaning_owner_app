import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';

import '../repository/orders_repo.dart';
import '../../data/models/fetch_order_details_usecase_model.dart';

@lazySingleton
class FetchOrderDetailsUsecaseUseCase implements UseCase<FetchOrderDetailsUsecaseModel, FetchOrderDetailsUsecaseParams> {

  final OrdersRepo orders;

  FetchOrderDetailsUsecaseUseCase({required this.orders});

  @override
  DataResponse<FetchOrderDetailsUsecaseModel> call(FetchOrderDetailsUsecaseParams params) {
    return orders.fetchOrderDetailsUsecase(params);
  }
}

class FetchOrderDetailsUsecaseParams with Params{}
