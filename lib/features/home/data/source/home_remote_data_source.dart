import 'package:common_package/helpers/dio_network.dart';
import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/api_handler.dart';
import '../models/fetch_home_page_usecase_model.dart';
import '../../domain/usecases/fetch_home_page_usecase_use_case.dart';

@lazySingleton
class HomeRemoteDataSource with HandlingApiManager {
  final DioNetwork dioNetwork;

  HomeRemoteDataSource({required this.dioNetwork});

  Future<FetchHomePageUsecaseModel> fetchHomePageUsecase(FetchHomePageUsecaseParams params) {
    return wrapHandlingApi(
      tryCall: () => dioNetwork.getData(endPoint: '/api/v1/cleaning/worker/homepage', params: params.getParams(), data: params.getBody().isEmpty ? null : params.getBody()),
      jsonConvert: fetchHomePageUsecaseModelFromJson,
    );
  }
}