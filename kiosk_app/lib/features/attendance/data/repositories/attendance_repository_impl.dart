import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> markAttendance(String base64Image, {String? machineId}) {
    return remoteDataSource.uploadAttendanceImage(base64Image, machineId: machineId);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentAttendance({String? machineId}) {
    return remoteDataSource.fetchRecentAttendance(machineId: machineId);
  }
}