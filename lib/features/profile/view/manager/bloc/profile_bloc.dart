import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:common_package/common_package.dart';
import '../../../domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import '../../../data/models/fetch_worker_profile_usecase_model.dart';
import '../../../domain/usecases/fetch_disputes_usecase_use_case.dart';
import '../../../data/models/fetch_disputes_usecase_model.dart';
import '../../../domain/usecases/fetch_dispute_details_usecase_use_case.dart';
import '../../../data/models/fetch_dispute_details_usecase_model.dart';
import '../../../domain/usecases/update_dispute_use_case.dart';
import '../../../data/models/update_dispute_model.dart';
import '../../../domain/usecases/fetch_worker_statistics_use_case.dart';
import '../../../data/models/fetch_worker_statistics_model.dart';
import '../../../domain/usecases/update_worker_work_areas_use_case.dart';
import '../../../data/models/worker_work_areas_model.dart';
import '../../../domain/usecases/update_worker_profile_use_case.dart';
import '../../../data/models/update_worker_profile_model.dart';
import '../../../data/models/fetch_notifications_model.dart';
import '../../../data/models/fetch_deposit_account_usecase_model.dart';
import '../../../data/models/fetch_deposit_transactions_usecase_model.dart';
import '../../../data/models/notification_api_models.dart';
import '../../../domain/usecases/fetch_deposit_account_use_case.dart';
import '../../../domain/usecases/fetch_deposit_transactions_use_case.dart';
import '../../../domain/usecases/fetch_notifications_use_case.dart';
import '../../../domain/usecases/mark_all_notifications_read_use_case.dart';
import '../../../domain/usecases/mark_notification_read_use_case.dart';
import '../../../domain/usecases/fetch_worker_reviews_use_case.dart';
import '../../../data/models/fetch_worker_reviews_model.dart';
import '../../../domain/usecases/fetch_cleaning_neighborhoods_use_case.dart';
import '../../../data/models/cleaning_neighborhood_model.dart';
import '../../../domain/usecases/fetch_worker_working_hours_use_case.dart';
import '../../../domain/usecases/update_worker_working_hours_use_case.dart';
import '../../../data/models/worker_working_hours_model.dart';
part 'profile_event.dart';

part 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FetchWorkerStatisticsUseCase fetchWorkerStatisticsUseCase;
  final FetchDisputeDetailsUsecaseUseCase fetchDisputeDetailsUsecaseUseCase;
  final FetchDisputesUsecaseUseCase fetchDisputesUsecaseUseCase;
  final FetchWorkerProfileUsecaseUseCase fetchWorkerProfileUsecaseUseCase;
  final UpdateWorkerWorkAreasUseCase updateWorkerWorkAreasUseCase;
  final UpdateDisputeUseCase updateDisputeUseCase;
  final UpdateWorkerProfileUseCase updateWorkerProfileUseCase;
  final FetchDepositAccountUseCase fetchDepositAccountUseCase;
  final FetchDepositTransactionsUseCase fetchDepositTransactionsUseCase;
  final FetchNotificationsUseCase fetchNotificationsUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final FetchWorkerReviewsUseCase fetchWorkerReviewsUseCase;
  final FetchCleaningNeighborhoodsUseCase fetchCleaningNeighborhoodsUseCase;
  final FetchWorkerWorkingHoursUseCase fetchWorkerWorkingHoursUseCase;
  final UpdateWorkerWorkingHoursUseCase updateWorkerWorkingHoursUseCase;

  ProfileBloc(
    this.fetchWorkerProfileUsecaseUseCase,
    this.fetchDisputesUsecaseUseCase,
    this.fetchDisputeDetailsUsecaseUseCase,
    this.fetchWorkerStatisticsUseCase,
    this.updateWorkerWorkAreasUseCase,
    this.updateDisputeUseCase,
    this.updateWorkerProfileUseCase,
    this.fetchDepositAccountUseCase,
    this.fetchDepositTransactionsUseCase,
    this.fetchNotificationsUseCase,
    this.markAllNotificationsReadUseCase,
    this.markNotificationReadUseCase,
    this.fetchWorkerReviewsUseCase,
    this.fetchCleaningNeighborhoodsUseCase,
    this.fetchWorkerWorkingHoursUseCase,
    this.updateWorkerWorkingHoursUseCase,
  ) : super(ProfileState()) {
    on<FetchWorkerProfileUsecaseEvent>(_fetchWorkerProfileUsecase);
    on<FetchDisputesUsecaseEvent>(
      _fetchDisputesUsecase,
      transformer: droppableProMax(),
    );
    on<FetchDisputeDetailsUsecaseEvent>(_fetchDisputeDetailsUsecase);
    on<UpdateDisputeEvent>(_updateDispute);
    on<FetchWorkerStatisticsEvent>(_fetchWorkerStatistics);
    on<UpdateWorkerWorkAreasEvent>(_updateWorkerWorkAreas);
    on<UpdateWorkerProfileEvent>(_updateWorkerProfile);
    on<FetchDepositAccountEvent>(_fetchDepositAccount);
    on<FetchDepositTransactionsEvent>(
      _fetchDepositTransactions,
      transformer: droppableProMax(),
    );
    on<FetchNotificationsEvent>(
      _fetchNotifications,
      transformer: droppableProMax(),
    );
    on<MarkAllNotificationsReadEvent>(_markAllNotificationsRead);
    on<MarkNotificationReadEvent>(_markNotificationRead);
    on<FetchWorkerReviewsEvent>(
      _fetchWorkerReviews,
      transformer: droppableProMax(),
    );
    on<FetchCleaningNeighborhoodsEvent>(_fetchCleaningNeighborhoods);
    on<FetchWorkerWorkingHoursEvent>(_fetchWorkerWorkingHours);
    on<UpdateWorkerWorkingHoursEvent>(_updateWorkerWorkingHours);
  }

  FutureOr<void> _fetchWorkerProfileUsecase(
    FetchWorkerProfileUsecaseEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(workerProfileUsecaseStatus: BlocStatus.loading));
    final res = await fetchWorkerProfileUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            workerProfileUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        SharedPreferencesHelper.saveData(
          key: 'user',
          value: fetchWorkerProfileUsecaseModelToJson(r),
        );
        emit(
          state.copyWith(
            workerProfileUsecaseStatus: BlocStatus.success,
            workerProfileUsecase: r,
            updateWorkerProfileStatus: BlocStatus.init,
          ),
        );
      },
    );
  }

  EventTransformer<T> droppableProMax<T extends EventWithReload>() {
    return (events, mapper) {
      return events.transform(ExhaustMapStreamTransformer(mapper));
    };
  }

  FutureOr<void> _fetchDisputesUsecase(
    FetchDisputesUsecaseEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (!state.disputesUsecase!.isEndPage || event.isReload) {
      emit(
        state.copyWith(
          disputesUsecase: state.disputesUsecase!.setLoading(
            isReload: event.isReload,
          ),
        ),
      );
      final res = await fetchDisputesUsecaseUseCase(event.params);
      res.fold(
        (l) {
          AppToast.showErrorGlobal(l.message);
          emit(
            state.copyWith(
              disputesUsecase: state.disputesUsecase!.setFaild(
                errorMessage: l.message,
              ),
              errorMessage: l.message,
            ),
          );
        },
        (r) {
          emit(
            state.copyWith(
              disputesUsecase: state.disputesUsecase!.setSuccess(data: r.data!),
            ),
          );
        },
      );
    }
  }

  FutureOr<void> _fetchDisputeDetailsUsecase(
    FetchDisputeDetailsUsecaseEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(disputeDetailsUsecaseStatus: BlocStatus.loading));
    final res = await fetchDisputeDetailsUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            disputeDetailsUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        emit(
          state.copyWith(
            disputeDetailsUsecaseStatus: BlocStatus.success,
            disputeDetailsUsecase: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _updateDispute(
    UpdateDisputeEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(updateDisputeStatus: BlocStatus.loading));
    final res = await updateDisputeUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            updateDisputeStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم تحديث النزاع');
        add(
          FetchDisputesUsecaseEvent(
            params: FetchDisputesUsecaseParams(page: 1, status: 'open'),
            isReload: true,
          ),
        );
        emit(
          state.copyWith(
            updateDisputeStatus: BlocStatus.success,
            updateDispute: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _fetchWorkerStatistics(
    FetchWorkerStatisticsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(workerStatisticsStatus: BlocStatus.loading));
    final res = await fetchWorkerStatisticsUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            workerStatisticsStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        emit(
          state.copyWith(
            workerStatisticsStatus: BlocStatus.success,
            workerStatistics: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _updateWorkerWorkAreas(
    UpdateWorkerWorkAreasEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(updateWorkAreasStatus: BlocStatus.loading));
    final res = await updateWorkerWorkAreasUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            updateWorkAreasStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم تحديث مناطق العمل');
        emit(
          state.copyWith(
            updateWorkAreasStatus: BlocStatus.success,
            workAreas: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _updateWorkerProfile(
    UpdateWorkerProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (event.showFeedback) {
      emit(state.copyWith(updateWorkerProfileStatus: BlocStatus.loading));
    }
    final res = await updateWorkerProfileUseCase(event.params);
    res.fold(
      (l) {
        if (event.showFeedback) {
          AppToast.showErrorGlobal(l.message);
          emit(
            state.copyWith(
              updateWorkerProfileStatus: BlocStatus.failed,
              errorMessage: l.message,
            ),
          );
        }
      },
      (r) {
        if (event.showFeedback) {
          AppToast.showSuccessGlobal('تم تحديث الملف الشخصي');
        }

        FetchWorkerProfileUsecaseModel? refreshedProfile;
        if (r.data != null) {
          refreshedProfile = FetchWorkerProfileUsecaseModel(data: r.data);
          SharedPreferencesHelper.saveData(
            key: 'user',
            value: fetchWorkerProfileUsecaseModelToJson(refreshedProfile),
          );
        }

        emit(
          state.copyWith(
            updateWorkerProfileStatus: event.showFeedback
                ? BlocStatus.success
                : state.updateWorkerProfileStatus,
            updateWorkerProfile: r,
            workerProfileUsecase:
                refreshedProfile ?? state.workerProfileUsecase,
            workerProfileUsecaseStatus: BlocStatus.success,
          ),
        );

        if (event.showFeedback) {
          add(
            FetchWorkerProfileUsecaseEvent(
              params: FetchWorkerProfileUsecaseParams(),
            ),
          );
        }
      },
    );
  }

  FutureOr<void> _fetchDepositAccount(
    FetchDepositAccountEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(depositAccountStatus: BlocStatus.loading));
    final response = await fetchDepositAccountUseCase(NoParams());
    response.fold(
      (failure) => emit(
        state.copyWith(
          depositAccountStatus: BlocStatus.failed,
          errorMessage: failure.message,
        ),
      ),
      (result) => emit(
        state.copyWith(
          depositAccountStatus: BlocStatus.success,
          depositAccount: result,
        ),
      ),
    );
  }

  FutureOr<void> _fetchDepositTransactions(
    FetchDepositTransactionsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final pagination = state.depositTransactionsPagination;
    final isLoadMore = event.loadMore && !event.isReload;
    if (isLoadMore && pagination.isEndPage) return;

    final activeTypeFilter = event.clearTypeFilter
        ? null
        : (event.typeFilter ??
              event.params.type ??
              state.depositTransactionsTypeFilter);
    final loadingPagination = pagination.setLoading(isReload: event.isReload);

    emit(
      state.copyWith(
        depositTransactionsTypeFilter: activeTypeFilter,
        clearDepositTransactionsTypeFilter: event.clearTypeFilter,
        depositTransactionsPagination: loadingPagination,
      ),
    );

    final page = isLoadMore ? pagination.pageNumber : 1;
    final perPage = event.params.perPage;
    final response = await fetchDepositTransactionsUseCase(
      FetchDepositTransactionsParams(
        page: page,
        perPage: perPage,
        type: activeTypeFilter,
      ),
    );
    response.fold(
      (failure) => emit(
        state.copyWith(
          depositTransactionsPagination: loadingPagination.setFaild(
            errorMessage: failure.message,
          ),
          errorMessage: failure.message,
        ),
      ),
      (result) => emit(
        state.copyWith(
          depositTransactionsTypeFilter: activeTypeFilter,
          clearDepositTransactionsTypeFilter: event.clearTypeFilter,
          depositTransactionsPagination: loadingPagination.setSuccess(
            data:
                result.data ??
                const <FetchDepositTransactionsUsecaseModelDataItem>[],
            perPage: result.meta?.perPage ?? perPage,
          ),
        ),
      ),
    );
  }

  FutureOr<void> _fetchNotifications(
    FetchNotificationsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final pagination = state.notificationsPagination;
    final isLoadMore = event.loadMore && !event.isReload;
    if (isLoadMore && pagination.isEndPage) return;

    emit(
      state.copyWith(
        notificationsPagination: pagination.setLoading(
          isReload: event.isReload,
        ),
        clearNotificationActionError: true,
      ),
    );

    final page = isLoadMore ? pagination.pageNumber : 1;
    final perPage = pagination.perPage;
    final response = await fetchNotificationsUseCase(
      FetchNotificationsParams(
        page: page,
        perPage: perPage,
        unreadOnly: event.params.unreadOnly,
      ),
    );
    response.fold(
      (failure) {
        emit(
          state.copyWith(
            notificationsPagination: pagination.setFaild(
              errorMessage: failure.message,
            ),
            errorMessage: failure.message,
          ),
        );
      },
      (result) {
        final mapped = (result.data ?? const <NotificationResourceModel>[])
            .map(_toNotificationItem)
            .toList();
        final countUnread = result.resolvedCountUnread;
        emit(
          state.copyWith(
            notificationsPagination: pagination.setSuccess(
              data: mapped,
              perPage: result.meta?.perPage ?? perPage,
            ),
            unreadNotification: countUnread,
          ),
        );
        if (event.markAllReadOnSuccess) {
          final hasUnread = (countUnread ?? 0) > 0 ||
              mapped.any((item) => item.isRead != true);
          if (hasUnread) {
            add(MarkAllNotificationsReadEvent(silent: true));
          }
        }
      },
    );
  }

  List<FetchNotificationsModelDataItem> _markNotificationsAsRead(
    List<FetchNotificationsModelDataItem> notifications,
  ) {
    return notifications
        .map(
          (item) => item.copyWith(isRead: true, showTrailingAccent: false),
        )
        .toList();
  }

  FutureOr<void> _markAllNotificationsRead(
    MarkAllNotificationsReadEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (!event.silent) {
      emit(
        state.copyWith(
          markAllNotificationsReadStatus: BlocStatus.loading,
          clearNotificationActionError: true,
          unreadNotification: 0,
        ),
      );
    }
    final response = await markAllNotificationsReadUseCase(NoParams());
    await response.fold(
      (failure) async {
        if (event.silent) return;
        emit(
          state.copyWith(
            clearMarkAllNotificationsReadStatus: true,
            notificationActionError: failure.message,
          ),
        );
      },
      (_) async {
        final updatedNotifications = _markNotificationsAsRead(
          state.notifications,
        );
        emit(
          state.copyWith(
            clearMarkAllNotificationsReadStatus: !event.silent,
            notificationsPagination: state.notificationsPagination.copyWith(
              list: updatedNotifications,
            ),
            unreadNotification: 0,
          ),
        );
      },
    );
  }

  FutureOr<void> _markNotificationRead(
    MarkNotificationReadEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final id = event.id.trim();
    if (id.isEmpty) return;

    final response = await markNotificationReadUseCase(
      MarkNotificationReadParams(notificationId: id),
    );
    response.fold(
      (failure) =>
          emit(state.copyWith(notificationActionError: failure.message)),
      (_) {
        final updated = state.notifications.map((item) {
          if (item.id == id) {
            return item.copyWith(isRead: true, showTrailingAccent: false);
          }
          return item;
        }).toList();
        emit(
          state.copyWith(
            notificationsPagination: state.notificationsPagination.copyWith(
              list: updated,
            ),
            notificationActionError: null,
          ),
        );
      },
    );
  }

  FetchNotificationsModelDataItem _toNotificationItem(
    NotificationResourceModel item,
  ) {
    final read = (item.readAt ?? '').trim().isNotEmpty;
    return FetchNotificationsModelDataItem(
      id: item.id,
      type: item.type ?? 'system',
      title: item.title,
      body: item.body,
      createdAt: item.createdAt,
      isRead: read,
      showTrailingAccent: !read,
      module: item.module,
      icon: item.icon,
      category: item.category,
      priority: item.priority,
      canonicalType: item.canonicalType,
      data: item.data,
    );
  }

  FutureOr<void> _fetchWorkerReviews(
    FetchWorkerReviewsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final currentReviews = state.workerReviews;
    final currentMeta = currentReviews?.meta;
    final isLoadMore = event.loadMore && !event.isReload;
    if (isLoadMore) {
      final currentPage = currentMeta?.currentPage;
      final lastPage = currentMeta?.lastPage;
      if (state.workerReviewsStatus == BlocStatus.loading ||
          currentPage == null ||
          lastPage == null ||
          currentPage >= lastPage) {
        return;
      }
    }

    emit(state.copyWith(workerReviewsStatus: BlocStatus.loading));
    final page = isLoadMore
        ? (currentMeta!.currentPage! + 1)
        : event.params.page;
    final res = await fetchWorkerReviewsUseCase(
      FetchWorkerReviewsParams(page: page, perPage: event.params.perPage),
    );
    res.fold(
      (failure) {
        emit(
          state.copyWith(
            workerReviewsStatus: BlocStatus.failed,
            errorMessage: failure.message,
          ),
        );
      },
      (result) {
        final reviews = result.data ?? const <WorkerReview>[];
        final mergedReviews = isLoadMore
            ? <WorkerReview>[
                ...(currentReviews?.data ?? const <WorkerReview>[]),
                ...reviews,
              ]
            : reviews;
        emit(
          state.copyWith(
            workerReviewsStatus: BlocStatus.success,
            workerReviews: FetchWorkerReviewsModel(
              data: mergedReviews,
              meta: result.meta,
            ),
          ),
        );
      },
    );
  }

  FutureOr<void> _fetchCleaningNeighborhoods(
    FetchCleaningNeighborhoodsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        cleaningNeighborhoodsStatus: BlocStatus.loading,
        clearCleaningNeighborhoodsErrorMessage: true,
      ),
    );
    final res = await fetchCleaningNeighborhoodsUseCase(event.params);
    res.fold(
      (l) {
        emit(
          state.copyWith(
            cleaningNeighborhoodsStatus: BlocStatus.failed,
            cleaningNeighborhoodsErrorMessage: l.message,
          ),
        );
      },
      (r) {
        emit(
          state.copyWith(
            cleaningNeighborhoodsStatus: BlocStatus.success,
            cleaningNeighborhoods: r.data,
            clearCleaningNeighborhoodsErrorMessage: true,
          ),
        );
      },
    );
  }

  FutureOr<void> _fetchWorkerWorkingHours(
    FetchWorkerWorkingHoursEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(fetchWorkingHoursStatus: BlocStatus.loading));
    final res = await fetchWorkerWorkingHoursUseCase(NoParams());
    res.fold(
      (l) {
        emit(
          state.copyWith(
            fetchWorkingHoursStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        emit(
          state.copyWith(
            fetchWorkingHoursStatus: BlocStatus.success,
            workingHours: r,
          ),
        );
      },
    );
  }

  FutureOr<void> _updateWorkerWorkingHours(
    UpdateWorkerWorkingHoursEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(updateWorkingHoursStatus: BlocStatus.loading));
    final res = await updateWorkerWorkingHoursUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            updateWorkingHoursStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        AppToast.showSuccessGlobal('تم تحديث ساعات العمل');

        final currentProfile = state.workerProfileUsecase;
        if (currentProfile?.data != null) {
          currentProfile!.data!.defaultWorkingHours = r.defaultWorkingHours;
          SharedPreferencesHelper.saveData(
            key: 'user',
            value: fetchWorkerProfileUsecaseModelToJson(currentProfile),
          );
        }

        emit(
          state.copyWith(
            updateWorkingHoursStatus: BlocStatus.success,
            workingHours: r,
            workerProfileUsecase: currentProfile ?? state.workerProfileUsecase,
          ),
        );
      },
    );
  }
}
