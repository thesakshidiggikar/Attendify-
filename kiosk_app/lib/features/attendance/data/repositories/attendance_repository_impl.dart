import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<dynamic>> getRecentEntries(String userId) {
    return remoteDataSource.fetchRecentEntries(userId);
  }

  @override
  Future<void> markAttendance(dynamic imageBytes) {
    return remoteDataSource.uploadAttendanceImage(imageBytes);
  }

  Future<List<Map<String, dynamic>>> getRecentAttendance() {
    return remoteDataSource.fetchRecentAttendance();
  }
} 