part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

/// Admin activates this phone as a kiosk machine
class MachineLoginRequested extends AuthEvent {
  final String machineId;
  final String adminPassword;
  const MachineLoginRequested(this.machineId, this.adminPassword);
  @override
  List<Object> get props => [machineId, adminPassword];
}

/// Check if machine is already activated on app start
class CheckMachineStatus extends AuthEvent {}

/// Deactivate this kiosk machine
class MachineLogoutRequested extends AuthEvent {}
