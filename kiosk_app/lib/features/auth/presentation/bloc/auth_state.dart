part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

/// Machine is activated and ready to scan faces
class MachineAuthenticated extends AuthState {
  final String machineId;
  const MachineAuthenticated({required this.machineId});
  @override
  List<Object> get props => [machineId];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object> get props => [message];
}
