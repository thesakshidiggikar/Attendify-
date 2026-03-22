part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

class FetchDashboardStatsRequested extends DashboardEvent {}

class SubmitManualAttendanceRequested extends DashboardEvent {
  final String userId;
  final String date;
  final String time;
  final String status;

  SubmitManualAttendanceRequested({
    required this.userId,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  List<Object?> get props => [userId, date, time, status];
}

class RegisterEmployeeRequested extends DashboardEvent {
  final String userId;
  final String fullName;
  final String email;
  final String password;
  final String profile;
  final String department;
  final dynamic image; // XFile

  RegisterEmployeeRequested({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.password,
    required this.profile,
    required this.department,
    required this.image,
  });

  @override
  List<Object?> get props => [userId, fullName, email, password, profile, department, image];
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