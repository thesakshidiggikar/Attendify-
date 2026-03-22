abstract class AttendanceRepository {
  Future<List<dynamic>> getRecentEntries(String userId);
  Future<void> markAttendance(dynamic imageBytes);
  Future<List<Map<String, dynamic>>> getRecentAttendance({String? userId});
}