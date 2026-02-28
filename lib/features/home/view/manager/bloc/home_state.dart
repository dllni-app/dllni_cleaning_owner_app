part of 'home_bloc.dart';

class HomeState {
  BlocStatus? homePageUsecaseStatus;
  FetchHomePageUsecaseModel? homePageUsecase;
  String? errorMessage;

  HomeState({
    this.errorMessage,
    this.homePageUsecase,
    this.homePageUsecaseStatus,
  });

  HomeState copyWith({
    String? errorMessage,
    FetchHomePageUsecaseModel? homePageUsecase,
    BlocStatus? homePageUsecaseStatus,
  }) =>
      HomeState(
        errorMessage: errorMessage ?? this.errorMessage,
        homePageUsecase: homePageUsecase ?? this.homePageUsecase,
        homePageUsecaseStatus: homePageUsecaseStatus ?? this.homePageUsecaseStatus,
      );}
