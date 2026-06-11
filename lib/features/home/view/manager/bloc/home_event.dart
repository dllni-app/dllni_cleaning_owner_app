part of 'home_bloc.dart';

abstract class HomeEvent {}

class FetchHomePageUsecaseEvent extends HomeEvent {
  final FetchHomePageUsecaseParams params;
  final bool silent;

  FetchHomePageUsecaseEvent({
    required this.params,
    this.silent = false,
  });
}
