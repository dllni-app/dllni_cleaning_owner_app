import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/error_handler.dart';

import '../../domain/repository/home_repo.dart';
import 'package:common_package/helpers/typedef.dart';
import '../source/home_remote_data_source.dart';
import '../../domain/usecases/fetch_home_page_usecase_use_case.dart';
import '../models/fetch_home_page_usecase_model.dart';

@LazySingleton(as: HomeRepo)
class HomeRepoImpl with HandlingException implements HomeRepo {
  final HomeRemoteDataSource homeRemoteDataSource;

  HomeRepoImpl({required this.homeRemoteDataSource});

  @override
  DataResponse<FetchHomePageUsecaseModel> fetchHomePageUsecase(FetchHomePageUsecaseParams params) {
    return wrapHandlingException(
      tryCall: () => homeRemoteDataSource.fetchHomePageUsecase(params),
    );
  }}

