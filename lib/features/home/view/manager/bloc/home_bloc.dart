import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
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

  FutureOr<void> _fetchHomePageUsecase(FetchHomePageUsecaseEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(homePageUsecaseStatus: BlocStatus.loading));
    final res = await fetchHomePageUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(state.copyWith(homePageUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        emit(state.copyWith(homePageUsecaseStatus: BlocStatus.success, homePageUsecase: r));
      },
    );
  }
}
