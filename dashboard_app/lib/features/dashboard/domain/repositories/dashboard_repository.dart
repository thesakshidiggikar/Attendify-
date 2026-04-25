import 'package:image_picker/image_picker.dart';
import '../entities/employee.dart';

abstract class DashboardRepository {
  Future<String> registerEmployee({
    required String userId,
    required String fullName,
    required String email,
    required String password,
    required String profile,
    required String department,
    required XFile image,
  });

  Future<List<Employee>> fetchAllEmployees();

  Future<void> submitManualAttendance({
    required String userId,
    required String date,
    required String time,
    required String status,
  });

  Future<Map<String, dynamic>> fetchAttendanceAnalytics();

  Future<List<Map<String, dynamic>>> fetchTodayAttendanceRecords();

  Future<void> deleteEmployee(String username);
}
