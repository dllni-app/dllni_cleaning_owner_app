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
  final bool showFeedback;

  UpdateWorkerProfileEvent({required this.params, this.showFeedback = true});
}

class FetchDepositAccountEvent extends ProfileEvent {}

class FetchDepositTransactionsEvent extends ProfileEvent with EventWithReload {
  final FetchDepositTransactionsParams params;
  final String? typeFilter;
  final bool clearTypeFilter;
  final bool loadMore;
  @override
  final bool isReload;

  FetchDepositTransactionsEvent({
    required this.params,
    this.typeFilter,
    this.clearTypeFilter = false,
    this.loadMore = false,
    this.isReload = false,
  });
}

class FetchNotificationsEvent extends ProfileEvent with EventWithReload {
  final FetchNotificationsParams params;
  final bool loadMore;
  @override
  final bool isReload;

  FetchNotificationsEvent({
    required this.params,
    this.loadMore = false,
    this.isReload = false,
  });
}

class MarkAllNotificationsReadEvent extends ProfileEvent {}

class MarkNotificationReadEvent extends ProfileEvent {
  final String id;

  MarkNotificationReadEvent({required this.id});
}

class FetchWorkerReviewsEvent extends ProfileEvent with EventWithReload {
  final FetchWorkerReviewsParams params;
  final bool loadMore;
  @override
  final bool isReload;

  FetchWorkerReviewsEvent({
    required this.params,
    this.loadMore = false,
    this.isReload = false,
  });
}
