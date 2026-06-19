import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:common_package/common_package.dart';
import '../../../domain/usecases/fetch_home_page_usecase_use_case.dart';
import '../../../data/models/fetch_home_page_usecase_model.dart';

part 'home_event.dart';

part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FetchHomePageUsecaseUseCase fetchHomePageUsecaseUseCase;

  HomeBloc(this.fetchHomePageUsecaseUseCase) : super(HomeState()) {
    on<FetchHomePageUsecaseEvent>(_fetchHomePageUsecase);
  }

  FutureOr<void> _fetchHomePageUsecase(
    FetchHomePageUsecaseEvent event,
    Emitter<HomeState> emit,
  ) async {
    final hasExistingData =
        state.homePageUsecaseStatus == BlocStatus.success &&
        state.homePageUsecase != null;

    if (!event.silent || !hasExistingData) {
      emit(state.copyWith(homePageUsecaseStatus: BlocStatus.loading));
    }

    final res = await fetchHomePageUsecaseUseCase(event.params);
    res.fold(
      (l) {
        if (event.silent && hasExistingData) {
          return;
        }
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            homePageUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        _cacheWorkerEligibility(r);
        emit(
          state.copyWith(
            homePageUsecaseStatus: BlocStatus.success,
            homePageUsecase: r,
          ),
        );
      },
    );
  }

  void _cacheWorkerEligibility(FetchHomePageUsecaseModel model) {
    final eligibility = model.dispatchEligibility;
    if (eligibility != null) {
      SharedPreferencesHelper.saveData(
        key: 'worker_dispatch_eligibility',
        value: jsonEncode(eligibility.toJson()),
      );
      SharedPreferencesHelper.saveData(
        key: 'worker_can_receive_new_requests',
        value: eligibility.canReceiveNewRequests == true,
      );
      SharedPreferencesHelper.saveData(
        key: 'worker_eligibility_message_ar',
        value: eligibility.userMessageAr,
      );
      return;
    }

    final canReceive = model.isEligibleForNewRequests ??
        model.depositSummary?.isEligibleForNewRequests;
    if (canReceive != null) {
      SharedPreferencesHelper.saveData(
        key: 'worker_can_receive_new_requests',
        value: canReceive,
      );
      if (!canReceive) {
        SharedPreferencesHelper.saveData(
          key: 'worker_eligibility_message_ar',
          value: model.eligibilityMessageAr,
        );
      }
    }
  }
}
