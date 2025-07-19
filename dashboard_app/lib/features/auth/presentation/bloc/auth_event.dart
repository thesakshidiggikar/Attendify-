part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  AuthLoginRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthNewPasswordRequired extends AuthEvent {
  final String username;
  final String newPassword;
  AuthNewPasswordRequired({required this.username, required this.newPassword});
  @override
  List<Object?> get props => [username, newPassword];
} 