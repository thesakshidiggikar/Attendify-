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
    
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.login(event.username, event.password);
        emit(AuthAuthenticated(user: user));
      } catch (e) {
        emit(AuthError(message: 'Login failed: $e'));
      }
    });
    
    on<AuthNewPasswordRequired>((event, emit) async {
      emit(AuthLoading());
      // This event is not needed for REST API login, but keeping for compatibility
      emit(AuthError(message: 'New password flow not supported with REST API'));
    });
    
    on<AuthLogoutRequested>((event, emit) async {
      // TODO: Clear stored token
      emit(AuthInitial());
    });
  }
} 