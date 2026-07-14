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
  BlocStatus? depositAccountStatus;
  FetchDepositAccountUsecaseModel? depositAccount;
  final PaginationStateModel<FetchDepositTransactionsUsecaseModelDataItem>
  depositTransactionsPagination;
  final String? depositTransactionsTypeFilter;
  final PaginationStateModel<FetchNotificationsModelDataItem>
  notificationsPagination;
  final int? unreadNotification;
  final BlocStatus? markAllNotificationsReadStatus;
  final String? notificationActionError;
  BlocStatus? workerReviewsStatus;
  FetchWorkerReviewsModel? workerReviews;
  BlocStatus? cleaningNeighborhoodsStatus;
  List<CleaningNeighborhoodModel>? cleaningNeighborhoods;
  String? cleaningNeighborhoodsErrorMessage;
  BlocStatus? fetchWorkingHoursStatus;
  BlocStatus? updateWorkingHoursStatus;
  WorkerWorkingHoursModel? workingHours;
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
    this.depositAccountStatus,
    this.depositAccount,
    this.depositTransactionsPagination =
        const PaginationStateModel<
          FetchDepositTransactionsUsecaseModelDataItem
        >(perPage: 20),
    this.depositTransactionsTypeFilter,
    this.notificationsPagination =
        const PaginationStateModel<FetchNotificationsModelDataItem>(
          perPage: 10,
        ),
    this.unreadNotification,
    this.markAllNotificationsReadStatus,
    this.notificationActionError,
    this.workerReviewsStatus,
    this.workerReviews,
    this.cleaningNeighborhoodsStatus,
    this.cleaningNeighborhoods,
    this.cleaningNeighborhoodsErrorMessage,
    this.fetchWorkingHoursStatus,
    this.updateWorkingHoursStatus,
    this.workingHours,
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
    BlocStatus? depositAccountStatus,
    FetchDepositAccountUsecaseModel? depositAccount,
    PaginationStateModel<FetchDepositTransactionsUsecaseModelDataItem>?
    depositTransactionsPagination,
    String? depositTransactionsTypeFilter,
    bool clearDepositTransactionsTypeFilter = false,
    PaginationStateModel<FetchNotificationsModelDataItem>?
    notificationsPagination,
    int? unreadNotification,
    bool clearUnreadNotification = false,
    BlocStatus? markAllNotificationsReadStatus,
    bool clearMarkAllNotificationsReadStatus = false,
    String? notificationActionError,
    bool clearNotificationActionError = false,
    BlocStatus? workerReviewsStatus,
    FetchWorkerReviewsModel? workerReviews,
    BlocStatus? cleaningNeighborhoodsStatus,
    List<CleaningNeighborhoodModel>? cleaningNeighborhoods,
    String? cleaningNeighborhoodsErrorMessage,
    bool clearCleaningNeighborhoodsErrorMessage = false,
    BlocStatus? fetchWorkingHoursStatus,
    BlocStatus? updateWorkingHoursStatus,
    WorkerWorkingHoursModel? workingHours,
  }) => ProfileState(
    errorMessage: errorMessage ?? this.errorMessage,
    workerProfileUsecase: workerProfileUsecase ?? this.workerProfileUsecase,
    workerProfileUsecaseStatus:
        workerProfileUsecaseStatus ?? this.workerProfileUsecaseStatus,
    disputesUsecase: disputesUsecase ?? this.disputesUsecase,
    disputeDetailsUsecase: disputeDetailsUsecase ?? this.disputeDetailsUsecase,
    disputeDetailsUsecaseStatus:
        disputeDetailsUsecaseStatus ?? this.disputeDetailsUsecaseStatus,
    workerStatistics: workerStatistics ?? this.workerStatistics,
    workerStatisticsStatus:
        workerStatisticsStatus ?? this.workerStatisticsStatus,
    workAreas: workAreas ?? this.workAreas,
    updateWorkAreasStatus: updateWorkAreasStatus ?? this.updateWorkAreasStatus,
    updateDisputeStatus: updateDisputeStatus ?? this.updateDisputeStatus,
    updateDispute: updateDispute ?? this.updateDispute,
    updateWorkerProfileStatus:
        updateWorkerProfileStatus ?? this.updateWorkerProfileStatus,
    updateWorkerProfile: updateWorkerProfile ?? this.updateWorkerProfile,
    depositAccountStatus: depositAccountStatus ?? this.depositAccountStatus,
    depositAccount: depositAccount ?? this.depositAccount,
    depositTransactionsPagination:
        depositTransactionsPagination ?? this.depositTransactionsPagination,
    depositTransactionsTypeFilter: clearDepositTransactionsTypeFilter
        ? null
        : (depositTransactionsTypeFilter ?? this.depositTransactionsTypeFilter),
    notificationsPagination:
        notificationsPagination ?? this.notificationsPagination,
    unreadNotification: clearUnreadNotification
        ? null
        : (unreadNotification ?? this.unreadNotification),
    markAllNotificationsReadStatus: clearMarkAllNotificationsReadStatus
        ? null
        : (markAllNotificationsReadStatus ??
              this.markAllNotificationsReadStatus),
    notificationActionError: clearNotificationActionError
        ? null
        : (notificationActionError ?? this.notificationActionError),
    workerReviewsStatus: workerReviewsStatus ?? this.workerReviewsStatus,
    workerReviews: workerReviews ?? this.workerReviews,
    cleaningNeighborhoodsStatus:
        cleaningNeighborhoodsStatus ?? this.cleaningNeighborhoodsStatus,
    cleaningNeighborhoods: cleaningNeighborhoods ?? this.cleaningNeighborhoods,
    cleaningNeighborhoodsErrorMessage: clearCleaningNeighborhoodsErrorMessage
        ? null
        : (cleaningNeighborhoodsErrorMessage ??
              this.cleaningNeighborhoodsErrorMessage),
    fetchWorkingHoursStatus:
        fetchWorkingHoursStatus ?? this.fetchWorkingHoursStatus,
    updateWorkingHoursStatus:
        updateWorkingHoursStatus ?? this.updateWorkingHoursStatus,
    workingHours: workingHours ?? this.workingHours,
  );

  BlocStatus get notificationsStatus => notificationsPagination.status;

  BlocStatus get depositTransactionsStatus =>
      depositTransactionsPagination.status;

  List<FetchNotificationsModelDataItem> get notifications =>
      notificationsPagination.list;

  List<FetchDepositTransactionsUsecaseModelDataItem> get depositTransactions =>
      depositTransactionsPagination.list;
}
