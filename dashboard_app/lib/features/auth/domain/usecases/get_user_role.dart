import '../repositories/auth_repository.dart';

class GetUserRole {
  final AuthRepository repository;
  GetUserRole(this.repository);
  Future<String> call() async {
    final user = await repository.getCurrentUser();
    return user.role;
  }
} 