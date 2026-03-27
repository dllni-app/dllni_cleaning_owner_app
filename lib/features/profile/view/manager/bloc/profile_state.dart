part of 'profile_bloc.dart';

class ProfileState {
  BlocStatus? workerStatisticsStatus;
  FetchWorkerStatisticsModel? workerStatistics;
  WorkerWorkAreasModel? workAreas;
  BlocStatus? updateWorkAreasStatus;
  BlocStatus? disputeDetailsUsecaseStatus;
  FetchDisputeDetailsUsecaseModel? disputeDetailsUsecase;
  PaginationStateModel<FetchDisputesUsecaseModelDataItem>? disputesUsecase;
  BlocStatus? workerProfileUsecaseStatus;
  FetchWorkerProfileUsecaseModel? workerProfileUsecase;
  BlocStatus? updateDisputeStatus;
  UpdateDisputeModel? updateDispute;
  BlocStatus? updateWorkerProfileStatus;
  UpdateWorkerProfileModel? updateWorkerProfile;
  String? errorMessage;

  ProfileState({
    this.errorMessage,
    this.workerProfileUsecase,
    this.workerProfileUsecaseStatus,
    this.disputesUsecase = const PaginationStateModel(perPage: 10),
    this.disputeDetailsUsecase,
    this.disputeDetailsUsecaseStatus,
    this.workerStatistics,
    this.workerStatisticsStatus,
    this.workAreas,
    this.updateWorkAreasStatus,
    this.updateDisputeStatus,
    this.updateDispute,
    this.updateWorkerProfileStatus,
    this.updateWorkerProfile,
  });

  ProfileState copyWith({
    String? errorMessage,
    FetchWorkerProfileUsecaseModel? workerProfileUsecase,
    BlocStatus? workerProfileUsecaseStatus,
    PaginationStateModel<FetchDisputesUsecaseModelDataItem>? disputesUsecase,
    FetchDisputeDetailsUsecaseModel? disputeDetailsUsecase,
    BlocStatus? disputeDetailsUsecaseStatus,
    FetchWorkerStatisticsModel? workerStatistics,
    BlocStatus? workerStatisticsStatus,
    WorkerWorkAreasModel? workAreas,
    BlocStatus? updateWorkAreasStatus,
    BlocStatus? updateDisputeStatus,
    UpdateDisputeModel? updateDispute,
    BlocStatus? updateWorkerProfileStatus,
    UpdateWorkerProfileModel? updateWorkerProfile,
  }) => ProfileState(
    errorMessage: errorMessage ?? this.errorMessage,
    workerProfileUsecase: workerProfileUsecase ?? this.workerProfileUsecase,
    workerProfileUsecaseStatus: workerProfileUsecaseStatus ?? this.workerProfileUsecaseStatus,
    disputesUsecase: disputesUsecase ?? this.disputesUsecase,
    disputeDetailsUsecase: disputeDetailsUsecase ?? this.disputeDetailsUsecase,
    disputeDetailsUsecaseStatus: disputeDetailsUsecaseStatus ?? this.disputeDetailsUsecaseStatus,
    workerStatistics: workerStatistics ?? this.workerStatistics,
    workerStatisticsStatus: workerStatisticsStatus ?? this.workerStatisticsStatus,
    workAreas: workAreas ?? this.workAreas,
    updateWorkAreasStatus: updateWorkAreasStatus ?? this.updateWorkAreasStatus,
    updateDisputeStatus: updateDisputeStatus ?? this.updateDisputeStatus,
    updateDispute: updateDispute ?? this.updateDispute,
    updateWorkerProfileStatus: updateWorkerProfileStatus ?? this.updateWorkerProfileStatus,
    updateWorkerProfile: updateWorkerProfile ?? this.updateWorkerProfile,
  );
}
