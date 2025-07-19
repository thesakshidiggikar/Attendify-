import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/employee_registration_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final EmployeeRegistrationRepository registrationRepository;
  List<Employee> _allEmployees = [];

  DashboardBloc({required this.registrationRepository}) : super(DashboardInitial()) {
    on<RegisterEmployeeRequested>((event, emit) async {
      emit(RegisterEmployeeInProgress());
      try {
        await registrationRepository.registerEmployee(
          username: event.username,
          email: event.email,
          password: event.password,
          profile: event.profile,
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
        final employees = await registrationRepository.fetchAllEmployees();
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
      if (currentState is EmployeesLoadSuccess) {
        emit(EmployeeDeleteInProgress(currentState.employees));
        try {
          await registrationRepository.deleteEmployee(event.username);
          final updated = currentState.employees.where((e) => e.username != event.username).toList();
          _allEmployees = _allEmployees.where((e) => e.username != event.username).toList();
          emit(EmployeeDeleteSuccess(updated));
          emit(EmployeesLoadSuccess(updated));
        } catch (e) {
          emit(EmployeeDeleteFailure(e.toString(), currentState.employees));
          emit(EmployeesLoadSuccess(currentState.employees));
        }
      }
    });
  }
} 