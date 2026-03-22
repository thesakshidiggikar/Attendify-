part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  const AuthLoginRequested(this.username, this.password);
  @override
  List<Object> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthBypassRequested extends AuthEvent {
  final String username;
  const AuthBypassRequested(this.username);
  @override
  List<Object> get props => [username];
}

class AuthNewPasswordRequired extends AuthEvent {
  final String username;
  final String newPassword;
  const AuthNewPasswordRequired({required this.username, required this.newPassword});
  @override
  List<Object> get props => [username, newPassword];
}
