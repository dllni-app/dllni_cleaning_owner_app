part of 'auth_bloc.dart';

abstract class AuthEvent {}

class LoginUsecaseEvent extends AuthEvent {
  final LoginUsecaseParams params;

  LoginUsecaseEvent({required this.params});
}
