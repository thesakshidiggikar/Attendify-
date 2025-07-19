import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id, 
    required super.name, 
    required super.role,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'employee',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'token': token,
    };
  }
} 