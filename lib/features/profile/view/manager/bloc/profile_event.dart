part of 'profile_bloc.dart';

abstract class ProfileEvent {}

class FetchWorkerProfileUsecaseEvent extends ProfileEvent {
  final FetchWorkerProfileUsecaseParams params;

  FetchWorkerProfileUsecaseEvent({required this.params});
}

class FetchDisputesUsecaseEvent extends ProfileEvent with EventWithReload {
  final FetchDisputesUsecaseParams params;

  @override
  final bool isReload;

  FetchDisputesUsecaseEvent({required this.params, this.isReload = false});
}

class FetchDisputeDetailsUsecaseEvent extends ProfileEvent {
  final FetchDisputeDetailsUsecaseParams params;

  FetchDisputeDetailsUsecaseEvent({required this.params});
}

class UpdateDisputeEvent extends ProfileEvent {
  final UpdateDisputeParams params;

  UpdateDisputeEvent({required this.params});
}

class FetchWorkerStatisticsEvent extends ProfileEvent {
  final FetchWorkerStatisticsParams params;

  FetchWorkerStatisticsEvent({required this.params});
}

class UpdateWorkerWorkAreasEvent extends ProfileEvent {
  final UpdateWorkerWorkAreasParams params;

  UpdateWorkerWorkAreasEvent({required this.params});
}

class UpdateWorkerProfileEvent extends ProfileEvent {
  final UpdateWorkerProfileParams params;

  UpdateWorkerProfileEvent({required this.params});
}
