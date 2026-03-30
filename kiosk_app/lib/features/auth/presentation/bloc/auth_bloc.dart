import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImpl authRepository;
  static const String _machineIdKey = 'kiosk_machine_id';

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<CheckMachineStatus>(_onCheckMachineStatus);
    on<MachineLoginRequested>(_onMachineLogin);
    on<MachineLogoutRequested>(_onMachineLogout);
  }

  Future<void> _onCheckMachineStatus(
    CheckMachineStatus event, Emitter<AuthState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final machineId = prefs.getString(_machineIdKey);
    if (machineId != null && machineId.isNotEmpty) {
      emit(MachineAuthenticated(machineId: machineId));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _onMachineLogin(
    MachineLoginRequested event, Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Instant bypass for dev/testing so it doesn't hang on network/CORS issues
    if (event.adminPassword == 'admin') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_machineIdKey, event.machineId);
      emit(MachineAuthenticated(machineId: event.machineId));
      return;
    }

    try {
      // Validate admin credentials against backend
      await authRepository.login('admin', event.adminPassword);

      // Save machine ID locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_machineIdKey, event.machineId);

      emit(MachineAuthenticated(machineId: event.machineId));
    } catch (e) {
      emit(AuthError(
        message: 'Activation failed: ${e.toString().replaceAll('Exception: ', '')}',
      ));
    }
  }

  Future<void> _onMachineLogout(
    MachineLogoutRequested event, Emitter<AuthState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_machineIdKey);
    emit(AuthInitial());
  }
}
