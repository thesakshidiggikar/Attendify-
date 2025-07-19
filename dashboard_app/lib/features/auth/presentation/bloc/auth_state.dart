part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}
class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthNewPasswordRequiredState extends AuthState {
  final String username;
  AuthNewPasswordRequiredState({required this.username});
  @override
  List<Object?> get props => [username];
} 