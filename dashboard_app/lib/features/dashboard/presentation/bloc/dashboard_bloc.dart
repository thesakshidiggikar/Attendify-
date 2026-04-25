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
        // Fetch employees and today's attendance records in parallel
        final results = await Future.wait([
          dashboardRepository.fetchAllEmployees(),
          dashboardRepository.fetchTodayAttendanceRecords(),
        ]);
        
        final employees = results[0] as List<Employee>;
        final attendanceRecords = results[1] as List<Map<String, dynamic>>;
        
        print('DEBUG: Attendance records found today: ${attendanceRecords.length}');

        // Cross-reference: mark each employee as Present or Absent based on real records
        final enrichedEmployees = employees.map((emp) {
          // Find if this student has a record in today's attendance data
          final record = attendanceRecords.cast<Map<String, dynamic>?>().firstWhere(
            (r) => 
              r?['user_id']?.toString().toLowerCase() == emp.cognitoUserId.toLowerCase() ||
              r?['user_id']?.toString().toLowerCase() == emp.username.toLowerCase() ||
              r?['username']?.toString().toLowerCase() == emp.cognitoUserId.toLowerCase() ||
              r?['username']?.toString().toLowerCase() == emp.username.toLowerCase(),
            orElse: () => null,
          );

          final isPresent = record != null;
          final time = record?['timestamp']?.toString();

          return Employee(
            username: emp.username,
            email: emp.email,
            profile: emp.profile,
            department: emp.department,
            faceId: emp.faceId,
            cognitoUserId: emp.cognitoUserId,
            attendanceStatus: isPresent ? 'Present' : 'Absent',
            attendanceTime: time,
          );
        }).toList();

        // Sort: show present students first, then by name
        enrichedEmployees.sort((a, b) {
           if (a.attendanceStatus == b.attendanceStatus) {
             return a.username.compareTo(b.username);
           }
           return a.attendanceStatus == 'Present' ? -1 : 1;
        });

        final int present = enrichedEmployees.where((e) => e.attendanceStatus == 'Present').length;
        final int absent = enrichedEmployees.where((e) => e.attendanceStatus == 'Absent').length;

        emit(DashboardStatsLoadSuccess(
          totalStudents: employees.length, 
          presentToday: present, 
          absentToday: absent,
          employees: enrichedEmployees,
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