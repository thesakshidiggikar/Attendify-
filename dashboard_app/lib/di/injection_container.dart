import 'package:get_it/get_it.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Auth dependencies - following the same pattern as registration
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(),
  );
} 