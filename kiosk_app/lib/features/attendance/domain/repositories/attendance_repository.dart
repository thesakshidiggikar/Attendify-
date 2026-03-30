abstract class AttendanceRepository {
  /// Mark attendance via face image. Returns student info map.
  Future<Map<String, dynamic>> markAttendance(String base64Image, {String? machineId});

  /// Fetch recent attendance logs for this kiosk machine.
  Future<List<Map<String, dynamic>>> getRecentAttendance({String? machineId});
}