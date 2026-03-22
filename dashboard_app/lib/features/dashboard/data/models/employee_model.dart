import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.username,
    required super.email,
    required super.profile,
    required super.department,
    required super.faceId,
    required super.cognitoUserId,
    super.attendanceStatus,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      username: json['name'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      profile: json['profile'] ?? 'Student',
      department: json['department'] ?? 'General',
      faceId: json['face_id'] ?? json['FaceId'] ?? '',
      cognitoUserId: json['user_id'] ?? json['cognito_user_id'] ?? '',
      attendanceStatus: 'Not Marked',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': username,
      'email': email,
      'profile': profile,
      'department': department,
      'face_id': faceId,
      'user_id': cognitoUserId,
    };
  }
}
