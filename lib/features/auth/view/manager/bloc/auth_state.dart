part of 'auth_bloc.dart';

class AuthState {
  BlocStatus? loginUsecaseStatus;
  LoginUsecaseModel? loginUsecase;
  String? errorMessage;

  AuthState({
    this.errorMessage,
    this.loginUsecase,
    this.loginUsecaseStatus,
  });

  AuthState copyWith({
    String? errorMessage,
    LoginUsecaseModel? loginUsecase,
    BlocStatus? loginUsecaseStatus,
  }) =>
      AuthState(
        errorMessage: errorMessage ?? this.errorMessage,
        loginUsecase: loginUsecase ?? this.loginUsecase,
        loginUsecaseStatus: loginUsecaseStatus ?? this.loginUsecaseStatus,
      );}
