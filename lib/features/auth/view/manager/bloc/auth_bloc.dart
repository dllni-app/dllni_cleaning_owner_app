import 'package:common_package/common_package.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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

  Future<void> _loginUsecase(
    LoginUsecaseEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(loginUsecaseStatus: BlocStatus.loading));
    final res = await loginUsecaseUseCase(event.params);
    res.fold(
      (l) {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            loginUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) {
        SharedPreferencesHelper.saveData(key: 'token', value: r.token!);
        final workerId = r.user?.workerId ?? r.user?.id;
        if (workerId != null) {
          SharedPreferencesHelper.saveData(key: 'worker_id', value: workerId);
        }
        AppToast.showSuccessGlobal('تم تسجيل الدخول بنجاح');
        emit(
          state.copyWith(
            loginUsecaseStatus: BlocStatus.success,
            loginUsecase: r,
          ),
        );
      },
    );
  }
}
