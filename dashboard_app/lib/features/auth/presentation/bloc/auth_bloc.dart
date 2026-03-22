import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // TODO: Implement authentication check using stored token
        emit(AuthInitial());
      } catch (e) {
        emit(AuthError(message: 'Authentication check failed: $e'));
      }
    });
    
    on<AuthBypassRequested>((event, emit) async {
      emit(AuthAuthenticated(
        user: User(
          id: 'ADMIN',
          name: event.username,
          role: 'admin',
        ),
      ));
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.login(event.username, event.password);
        emit(AuthAuthenticated(user: user));
      } catch (e) {
        if (e.toString().contains('NEW_PASSWORD_REQUIRED')) {
          emit(AuthNewPasswordRequiredState(username: event.username));
        } else {
          emit(AuthError(message: 'Login failed: ${e.toString().replaceAll('Exception: ', '')}'));
        }
      }
    });
    
    on<AuthNewPasswordRequired>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.confirmNewPassword(event.username, event.newPassword);
        emit(AuthAuthenticated(user: user));
      } catch (e) {
        emit(AuthError(message: 'Failed to update password: ${e.toString().replaceAll('Exception: ', '')}'));
      }
    });
    
    on<AuthLogoutRequested>((event, emit) async {
      // TODO: Clear stored token
      emit(AuthInitial());
    });
  }
} 