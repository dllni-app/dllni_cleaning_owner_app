import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:common_package/helpers/pagination_helper.dart';
import '../../../domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import '../../../data/models/fetch_worker_profile_usecase_model.dart';
import 'package:common_package/helpers/droppable_helper.dart';
import '../../../domain/usecases/fetch_disputes_usecase_use_case.dart';
import '../../../data/models/fetch_disputes_usecase_model.dart';
import '../../../domain/usecases/fetch_dispute_details_usecase_use_case.dart';
import '../../../data/models/fetch_dispute_details_usecase_model.dart';

part 'profile_event.dart';
part 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FetchDisputeDetailsUsecaseUseCase fetchDisputeDetailsUsecaseUseCase;
  final FetchDisputesUsecaseUseCase fetchDisputesUsecaseUseCase;
  final FetchWorkerProfileUsecaseUseCase fetchWorkerProfileUsecaseUseCase;
  ProfileBloc(
    this.fetchWorkerProfileUsecaseUseCase,
    this.fetchDisputesUsecaseUseCase,
    this.fetchDisputeDetailsUsecaseUseCase,) : super(ProfileState()) {
    
  
    on<FetchWorkerProfileUsecaseEvent>(_fetchWorkerProfileUsecase);
    on<FetchDisputesUsecaseEvent>(_fetchDisputesUsecase, transformer: droppableProMax());
    on<FetchDisputeDetailsUsecaseEvent>(_fetchDisputeDetailsUsecase);}


  FutureOr<void> _fetchWorkerProfileUsecase(FetchWorkerProfileUsecaseEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(workerProfileUsecaseStatus: BlocStatus.loading));
    final res = await fetchWorkerProfileUsecaseUseCase(event.params);
    res.fold((l) {
      emit(state.copyWith(
        workerProfileUsecaseStatus: BlocStatus.failed,
        errorMessage: l.message,
      ));
    }, (r) {
      emit(state.copyWith(
        workerProfileUsecaseStatus: BlocStatus.success,
        workerProfileUsecase: r,
      ));
    });
  }

  EventTransformer<T> droppableProMax<T extends EventWithReload>() {
    return (events, mapper) {
      return events.transform(ExhaustMapStreamTransformer(mapper));
    };
  }

  FutureOr<void> _fetchDisputesUsecase(FetchDisputesUsecaseEvent event, Emitter<ProfileState> emit) async {
    if (!state.disputesUsecase!.isEndPage || event.isReload) {
      emit(state.copyWith(
        disputesUsecase: state.disputesUsecase!.setLoading(isReload: event.isReload),
      ));
      final res = await fetchDisputesUsecaseUseCase(event.params);
      res.fold((l) {
        emit(state.copyWith(
          disputesUsecase: state.disputesUsecase!.setFaild(errorMessage: l.message),
          errorMessage: l.message,
        ));
      }, (r) {
        emit(state.copyWith(
          disputesUsecase: state.disputesUsecase!.setSuccess(data: r.data!),
        ));
      });
    }
  }

  FutureOr<void> _fetchDisputeDetailsUsecase(FetchDisputeDetailsUsecaseEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(disputeDetailsUsecaseStatus: BlocStatus.loading));
    final res = await fetchDisputeDetailsUsecaseUseCase(event.params);
    res.fold((l) {
      emit(state.copyWith(
        disputeDetailsUsecaseStatus: BlocStatus.failed,
        errorMessage: l.message,
      ));
    }, (r) {
      emit(state.copyWith(
        disputeDetailsUsecaseStatus: BlocStatus.success,
        disputeDetailsUsecase: r,
      ));
    });
  }}
