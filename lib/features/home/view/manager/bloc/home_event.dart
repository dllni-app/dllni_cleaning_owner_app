part of 'home_bloc.dart';

abstract class HomeEvent {}

class FetchHomePageUsecaseEvent extends HomeEvent {
  final FetchHomePageUsecaseParams params;

  FetchHomePageUsecaseEvent({required this.params});
}
