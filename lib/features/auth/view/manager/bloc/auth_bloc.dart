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
    await NotificationHelper.getToken(LoginUsecaseParams.fcmTokenPrefsKey);
    final res = await loginUsecaseUseCase(event.params);
    await res.fold(
      (l) async {
        AppToast.showErrorGlobal(l.message);
        emit(
          state.copyWith(
            loginUsecaseStatus: BlocStatus.failed,
            errorMessage: l.message,
          ),
        );
      },
      (r) async {
        await SharedPreferencesHelper.saveData(key: 'token', value: r.token!);
        final workerId = r.user?.workerId;
        if (workerId != null && workerId > 0) {
          await SharedPreferencesHelper.saveData(
            key: 'worker_id',
            value: workerId,
          );
        } else {
          await SharedPreferencesHelper.removeData(key: 'worker_id');
        }
        await NotificationHelper.syncStoredToken(
          tokenKey: LoginUsecaseParams.fcmTokenPrefsKey,
        );
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
