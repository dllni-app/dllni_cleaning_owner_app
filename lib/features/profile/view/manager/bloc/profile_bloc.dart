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
import '../../../data/models/notification_api_models.dart';
import '../../../domain/usecases/fetch_notifications_use_case.dart';
import '../../../domain/usecases/mark_all_notifications_read_use_case.dart';
import '../../../domain/usecases/mark_notification_read_use_case.dart';
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
  final FetchNotificationsUseCase fetchNotificationsUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;

  ProfileBloc(
    this.fetchWorkerProfileUsecaseUseCase,
    this.fetchDisputesUsecaseUseCase,
    this.fetchDisputeDetailsUsecaseUseCase,
    this.fetchWorkerStatisticsUseCase,
    this.updateWorkerWorkAreasUseCase,
    this.updateDisputeUseCase,
    this.updateWorkerProfileUseCase,
    this.fetchNotificationsUseCase,
    this.markAllNotificationsReadUseCase,
    this.markNotificationReadUseCase,
  ) : super(ProfileState()) {
    on<FetchWorkerProfileUsecaseEvent>(_fetchWorkerProfileUsecase);
    on<FetchDisputesUsecaseEvent>(_fetchDisputesUsecase, transformer: droppableProMax());
    on<FetchDisputeDetailsUsecaseEvent>(_fetchDisputeDetailsUsecase);
    on<UpdateDisputeEvent>(_updateDispute);
    on<FetchWorkerStatisticsEvent>(_fetchWorkerStatistics);
    on<UpdateWorkerWorkAreasEvent>(_updateWorkerWorkAreas);
    on<UpdateWorkerProfileEvent>(_updateWorkerProfile);
    on<FetchNotificationsEvent>(_fetchNotifications, transformer: droppableProMax());
    on<MarkAllNotificationsReadEvent>(_markAllNotificationsRead);
    on<MarkNotificationReadEvent>(_markNotificationRead);
  }

  FutureOr<void> _fetchWorkerProfileUsecase(FetchWorkerProfileUsecaseEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(workerProfileUsecaseStatus: BlocStatus.loading));
    final res = await fetchWorkerProfileUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(state.copyWith(workerProfileUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        SharedPreferencesHelper.saveData(key: 'user', value: fetchWorkerProfileUsecaseModelToJson(r));
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

  FutureOr<void> _fetchDisputesUsecase(FetchDisputesUsecaseEvent event, Emitter<ProfileState> emit) async {
    if (!state.disputesUsecase!.isEndPage || event.isReload) {
      emit(state.copyWith(disputesUsecase: state.disputesUsecase!.setLoading(isReload: event.isReload)));
      final res = await fetchDisputesUsecaseUseCase(event.params);
      res.fold(
        (l) {
          AppToast.showErrorGlobal(l.message);
          emit(
            state.copyWith(
              disputesUsecase: state.disputesUsecase!.setFaild(errorMessage: l.message),
              errorMessage: l.message,
            ),
          );
        },
        (r) {
          emit(state.copyWith(disputesUsecase: state.disputesUsecase!.setSuccess(data: r.data!)));
        },
      );
    }
  }

  FutureOr<void> _fetchDisputeDetailsUsecase(FetchDisputeDetailsUsecaseEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(disputeDetailsUsecaseStatus: BlocStatus.loading));
    final res = await fetchDisputeDetailsUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(state.copyWith(disputeDetailsUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(disputeDetailsUsecaseStatus: BlocStatus.success, disputeDetailsUsecase: r));
      },
    );
  }

  FutureOr<void> _updateDispute(UpdateDisputeEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(updateDisputeStatus: BlocStatus.loading));
    final res = await updateDisputeUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(state.copyWith(updateDisputeStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        AppToast.showSuccessGlobal('تم تحديث النزاع');
        add(FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1, status: 'open'), isReload: true));
        emit(state.copyWith(updateDisputeStatus: BlocStatus.success, updateDispute: r));
      },
    );
  }

  FutureOr<void> _fetchWorkerStatistics(FetchWorkerStatisticsEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(workerStatisticsStatus: BlocStatus.loading));
    final res = await fetchWorkerStatisticsUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(state.copyWith(workerStatisticsStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(workerStatisticsStatus: BlocStatus.success, workerStatistics: r));
      },
    );
  }

  FutureOr<void> _updateWorkerWorkAreas(UpdateWorkerWorkAreasEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(updateWorkAreasStatus: BlocStatus.loading));
    final res = await updateWorkerWorkAreasUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(state.copyWith(updateWorkAreasStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        AppToast.showSuccessGlobal('تم تحديث مناطق العمل');
        emit(state.copyWith(updateWorkAreasStatus: BlocStatus.success, workAreas: r));
      },
    );
  }

  FutureOr<void> _updateWorkerProfile(UpdateWorkerProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(updateWorkerProfileStatus: BlocStatus.loading));
    final res = await updateWorkerProfileUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(state.copyWith(updateWorkerProfileStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        AppToast.showSuccessGlobal('تم تحديث الملف الشخصي');

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
            updateWorkerProfileStatus: BlocStatus.success,
            updateWorkerProfile: r,
            workerProfileUsecase: refreshedProfile ?? state.workerProfileUsecase,
            workerProfileUsecaseStatus: BlocStatus.success,
          ),
        );

        add(FetchWorkerProfileUsecaseEvent(params: FetchWorkerProfileUsecaseParams()));
      },
    );
  }

  FutureOr<void> _fetchNotifications(FetchNotificationsEvent event, Emitter<ProfileState> emit) async {
    final pagination = state.notificationsPagination;
    final isLoadMore = event.loadMore && !event.isReload;
    if (isLoadMore && pagination.isEndPage) return;

    emit(
      state.copyWith(
        notificationsPagination: pagination.setLoading(isReload: event.isReload),
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
      (failure) => emit(
        state.copyWith(
          notificationsPagination: pagination.setFaild(errorMessage: failure.message),
          errorMessage: failure.message,
        ),
      ),
      (result) {
        final mapped = (result.data ?? const <NotificationResourceModel>[]).map(_toNotificationItem).toList();
        emit(
          state.copyWith(
            notificationsPagination: pagination.setSuccess(
              data: mapped,
              perPage: result.meta?.perPage ?? perPage,
            ),
          ),
        );
      },
    );
  }

  FutureOr<void> _markAllNotificationsRead(MarkAllNotificationsReadEvent event, Emitter<ProfileState> emit) async {
    emit(
      state.copyWith(
        markAllNotificationsReadStatus: BlocStatus.loading,
        clearNotificationActionError: true,
      ),
    );
    final response = await markAllNotificationsReadUseCase(NoParams());
    await response.fold(
      (failure) async {
        emit(
          state.copyWith(
            clearMarkAllNotificationsReadStatus: true,
            notificationActionError: failure.message,
          ),
        );
      },
      (_) async {
        final updatedNotifications = state.notifications
            .map((item) => item.copyWith(isRead: true, showTrailingAccent: false))
            .toList();
        emit(
          state.copyWith(
            clearMarkAllNotificationsReadStatus: true,
            notificationsPagination: state.notificationsPagination.copyWith(list: updatedNotifications),
          ),
        );
      },
    );
  }

  FutureOr<void> _markNotificationRead(MarkNotificationReadEvent event, Emitter<ProfileState> emit) async {
    final id = event.id.trim();
    if (id.isEmpty) return;

    final response = await markNotificationReadUseCase(MarkNotificationReadParams(notificationId: id));
    response.fold(
      (failure) => emit(state.copyWith(notificationActionError: failure.message)),
      (_) {
        final updated = state.notifications.map((item) {
          if (item.id == id) {
            return item.copyWith(isRead: true, showTrailingAccent: false);
          }
          return item;
        }).toList();
        emit(
          state.copyWith(
            notificationsPagination: state.notificationsPagination.copyWith(list: updated),
            notificationActionError: null,
          ),
        );
      },
    );
  }

  FetchNotificationsModelDataItem _toNotificationItem(NotificationResourceModel item) {
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
}
