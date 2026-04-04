import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/dashboard_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository dashboardRepository;
  List<Employee> _allEmployees = [];

  DashboardBloc({required this.dashboardRepository}) : super(DashboardInitial()) {
    on<FetchDashboardStatsRequested>((event, emit) async {
      emit(DashboardStatsLoadInProgress());
      try {
        final employees = await dashboardRepository.fetchAllEmployees();
        int total = employees.length;
        
        int present = 0;
        int absent = 0;
        try {
          final analytics = await dashboardRepository.fetchAttendanceAnalytics();
          print('DEBUG: Analytics map: $analytics');
          // Map to the specific keys found in your Lambda response: total_records, present_count, absent_count
if (analytics['present_today'] != null) {
  present = (analytics['present_today'] as num).toInt();
}
if (analytics['absent_today'] != null) {
  absent = (analytics['absent_today'] as num).toInt();
}
          print('DEBUG: Parsed present: $present, absent: $absent');
        } catch (e) {
          print('DEBUG: Analytics fetch/parse error: $e');
          // Keep 0 if analytics API fails or isn't fully structured yet
        }
        
        emit(DashboardStatsLoadSuccess(
          totalStudents: total, 
          presentToday: present, 
          absentToday: absent,
          employees: employees,
        ));
      } catch (e) {
        emit(DashboardStatsLoadFailure(e.toString()));
      }
    });

    on<SubmitManualAttendanceRequested>((event, emit) async {
      emit(ManualAttendanceSubmitInProgress());
      try {
        await dashboardRepository.submitManualAttendance(
          userId: event.userId,
          date: event.date,
          time: event.time,
          status: event.status,
        );
        emit(ManualAttendanceSubmitSuccess());
      } catch (e) {
        emit(ManualAttendanceSubmitFailure(e.toString()));
      }
    });

    on<RegisterEmployeeRequested>((event, emit) async {
      emit(RegisterEmployeeInProgress());
      try {
        await dashboardRepository.registerEmployee(
          userId: event.userId,
          fullName: event.fullName,
          email: event.email,
          password: event.password,
          profile: event.profile,
          department: event.department,
          image: event.image,
        );
        emit(RegisterEmployeeSuccess());
      } catch (e) {
        emit(RegisterEmployeeFailure(e.toString()));
      }
    });

    on<FetchAllEmployeesRequested>((event, emit) async {
      emit(EmployeesLoadInProgress());
      try {
        final employees = await dashboardRepository.fetchAllEmployees();
        _allEmployees = employees;
        emit(EmployeesLoadSuccess(employees));
      } catch (e) {
        emit(EmployeesLoadFailure(e.toString()));
      }
    });

    on<SearchEmployeesChanged>((event, emit) {
      final query = event.query.toLowerCase();
      final filtered = _allEmployees.where((e) =>
        e.username.toLowerCase().contains(query) ||
        e.profile.toLowerCase().contains(query)
      ).toList();
      emit(EmployeesLoadSuccess(filtered));
    });

    on<DeleteEmployeeRequested>((event, emit) async {
      final currentState = state;
      List<Employee> currentEmployees = [];
      int currentTotal = 0;
      int currentPresent = 0;
      int currentAbsent = 0;

      if (currentState is DashboardStatsLoadSuccess) {
        currentEmployees = currentState.employees;
        currentTotal = currentState.totalStudents;
        currentPresent = currentState.presentToday;
        currentAbsent = currentState.absentToday;
      } else if (currentState is EmployeesLoadSuccess) {
        currentEmployees = currentState.employees;
        currentTotal = currentEmployees.length;
      }

      if (currentEmployees.isNotEmpty) {
        emit(EmployeeDeleteInProgress(currentEmployees));
        try {
          await dashboardRepository.deleteEmployee(event.username);
          final updated = currentEmployees.where((e) => e.cognitoUserId != event.username).toList();
          _allEmployees = _allEmployees.where((e) => e.cognitoUserId != event.username).toList();
          
          emit(EmployeeDeleteSuccess(updated));
          // Emit DashboardStatsLoadSuccess to update the Overview page counts immediately
          emit(DashboardStatsLoadSuccess(
            totalStudents: updated.length,
            presentToday: currentPresent,
            absentToday: currentAbsent,
            employees: updated,
          ));
        } catch (e) {
          emit(EmployeeDeleteFailure(e.toString(), currentEmployees));
          emit(EmployeesLoadSuccess(currentEmployees));
        }
      }
    });
  }
} 