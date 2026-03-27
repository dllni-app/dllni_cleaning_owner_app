import 'package:common_package/common_package.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:common_package/helpers/pagination_helper.dart';
import '../../../domain/usecases/login_usecase_use_case.dart';
import '../../../data/models/login_usecase_model.dart';

part 'auth_event.dart';

part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecaseUseCase loginUsecaseUseCase;

  AuthBloc(this.loginUsecaseUseCase) : super(AuthState()) {
    on<LoginUsecaseEvent>(_loginUsecase);
  }

  FutureOr<void> _loginUsecase(LoginUsecaseEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(loginUsecaseStatus: BlocStatus.loading));
    final res = await loginUsecaseUseCase(event.params);
    res.fold(
      (l) {
        emit(state.copyWith(loginUsecaseStatus: BlocStatus.failed, errorMessage: l.message));
      },
      (r) {
        SharedPreferencesHelper.saveData(key: 'token', value: r.token!);
        emit(state.copyWith(loginUsecaseStatus: BlocStatus.success, loginUsecase: r));
      },
    );
  }
}
