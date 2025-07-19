part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

class RegisterEmployeeRequested extends DashboardEvent {
  final String username;
  final String email;
  final String password;
  final String profile;
  final dynamic image; // XFile

  RegisterEmployeeRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.profile,
    required this.image,
  });

  @override
  List<Object?> get props => [username, email, password, profile, image];
}

class FetchAllEmployeesRequested extends DashboardEvent {}

class SearchEmployeesChanged extends DashboardEvent {
  final String query;
  SearchEmployeesChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class DeleteEmployeeRequested extends DashboardEvent {
  final String username;
  DeleteEmployeeRequested(this.username);
  @override
  List<Object?> get props => [username];
} 