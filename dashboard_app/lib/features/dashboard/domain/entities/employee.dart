import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final String username;
  final String email;
  final String profile;
  final String department;
  final String faceId;
  final String cognitoUserId;
  final String attendanceStatus;
  final String? attendanceTime;

  const Employee({
    required this.username,
    required this.email,
    required this.profile,
    required this.department,
    required this.faceId,
    required this.cognitoUserId,
    this.attendanceStatus = 'Absent',
    this.attendanceTime,
  });

  @override
  List<Object?> get props => [
        username,
        email,
        profile,
        department,
        faceId,
        cognitoUserId,
        attendanceStatus,
        attendanceTime,
      ];
}
