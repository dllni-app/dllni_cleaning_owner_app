part of 'profile_bloc.dart';

class ProfileState {
  BlocStatus? disputeDetailsUsecaseStatus;
  FetchDisputeDetailsUsecaseModel? disputeDetailsUsecase;
  PaginationStateModel<FetchDisputesUsecaseModelDataItem>? disputesUsecase;
  BlocStatus? workerProfileUsecaseStatus;
  FetchWorkerProfileUsecaseModel? workerProfileUsecase;
  String? errorMessage;

  ProfileState({
    this.errorMessage,
    this.workerProfileUsecase,
    this.workerProfileUsecaseStatus,
    this.disputesUsecase = const PaginationStateModel(perPage: 10),
    this.disputeDetailsUsecase,
    this.disputeDetailsUsecaseStatus,
  });

  ProfileState copyWith({
    String? errorMessage,
    FetchWorkerProfileUsecaseModel? workerProfileUsecase,
    BlocStatus? workerProfileUsecaseStatus,
    PaginationStateModel<FetchDisputesUsecaseModelDataItem>? disputesUsecase,
    FetchDisputeDetailsUsecaseModel? disputeDetailsUsecase,
    BlocStatus? disputeDetailsUsecaseStatus,
  }) => ProfileState(
    errorMessage: errorMessage ?? this.errorMessage,
    workerProfileUsecase: workerProfileUsecase ?? this.workerProfileUsecase,
    workerProfileUsecaseStatus: workerProfileUsecaseStatus ?? this.workerProfileUsecaseStatus,
    disputesUsecase: disputesUsecase ?? this.disputesUsecase,
    disputeDetailsUsecase: disputeDetailsUsecase ?? this.disputeDetailsUsecase,
    disputeDetailsUsecaseStatus: disputeDetailsUsecaseStatus ?? this.disputeDetailsUsecaseStatus,
  );
}
