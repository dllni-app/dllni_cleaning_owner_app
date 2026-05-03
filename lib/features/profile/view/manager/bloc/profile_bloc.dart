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
import '../../../../auth/data/models/login_usecase_model.dart';

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

  ProfileBloc(
    this.fetchWorkerProfileUsecaseUseCase,
    this.fetchDisputesUsecaseUseCase,
    this.fetchDisputeDetailsUsecaseUseCase,
    this.fetchWorkerStatisticsUseCase,
    this.updateWorkerWorkAreasUseCase,
    this.updateDisputeUseCase,
    this.updateWorkerProfileUseCase,
  ) : super(ProfileState()) {
    on<FetchWorkerProfileUsecaseEvent>(_fetchWorkerProfileUsecase);
    on<FetchDisputesUsecaseEvent>(_fetchDisputesUsecase, transformer: droppableProMax());
    on<FetchDisputeDetailsUsecaseEvent>(_fetchDisputeDetailsUsecase);
    on<UpdateDisputeEvent>(_updateDispute);
    on<FetchWorkerStatisticsEvent>(_fetchWorkerStatistics);
    on<UpdateWorkerWorkAreasEvent>(_updateWorkerWorkAreas);
    on<UpdateWorkerProfileEvent>(_updateWorkerProfile);
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
        emit(state.copyWith(workerProfileUsecaseStatus: BlocStatus.success, workerProfileUsecase: r));
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
        // Update local session data
        final userJson = SharedPreferencesHelper.getData(key: 'user');
        if (userJson != null) {
          final loginModel = loginUsecaseModelFromJson(userJson);
          if (r.data != null) {
            loginModel.user = LoginUsecaseModelUser.fromJson(r.data!.toJson());
            SharedPreferencesHelper.saveData(key: 'user', value: loginUsecaseModelToJson(loginModel));
          }
        }

        add(FetchWorkerProfileUsecaseEvent(params: FetchWorkerProfileUsecaseParams()));
        emit(state.copyWith(updateWorkerProfileStatus: BlocStatus.success, updateWorkerProfile: r));
      },
    );
  }
}
