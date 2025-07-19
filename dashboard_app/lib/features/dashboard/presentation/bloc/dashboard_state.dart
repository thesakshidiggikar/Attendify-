part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  // Add analytics, attendance, etc. fields here
  // final List<Analytics> analytics;
  // DashboardLoaded(this.analytics);
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
class RegisterEmployeeInProgress extends DashboardState {}
class RegisterEmployeeSuccess extends DashboardState {}
class RegisterEmployeeFailure extends DashboardState {
  final String error;
  RegisterEmployeeFailure(this.error);
  @override
  List<Object?> get props => [error];
}
class EmployeesLoadInProgress extends DashboardState {}
class EmployeesLoadSuccess extends DashboardState {
  final List<Employee> employees;
  EmployeesLoadSuccess(this.employees);
  @override
  List<Object?> get props => [employees];
}
class EmployeesLoadFailure extends DashboardState {
  final String error;
  EmployeesLoadFailure(this.error);
  @override
  List<Object?> get props => [error];
}
class EmployeeDeleteInProgress extends DashboardState {
  final List<Employee> employees;
  EmployeeDeleteInProgress(this.employees);
  @override
  List<Object?> get props => [employees];
}
class EmployeeDeleteSuccess extends DashboardState {
  final List<Employee> employees;
  EmployeeDeleteSuccess(this.employees);
  @override
  List<Object?> get props => [employees];
}
class EmployeeDeleteFailure extends DashboardState {
  final String error;
  final List<Employee> employees;
  EmployeeDeleteFailure(this.error, this.employees);
  @override
  List<Object?> get props => [error, employees];
} 