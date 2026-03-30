import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/employee_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final String apiBaseUrl;

  DashboardRepositoryImpl({required this.apiBaseUrl});

  @override
  Future<String> registerEmployee({
    required String userId,
    required String fullName,
    required String email,
    required String password,
    required String profile,
    required String department,
    required XFile image,
  }) async {
    final imageBytes = await image.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);

    final registerResp = await http.post(
      Uri.parse('$apiBaseUrl/user-service'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': fullName,
        'department': department,
        'image': imageBase64, // Lambda expects 'image' key
      }),
    );

    if (registerResp.statusCode != 200) {
      throw Exception('Failed to register user: \n${registerResp.body}');
    }
    
    final registerData = jsonDecode(registerResp.body);
    return registerData['user_id'] ?? 'Success';
  }

  @override
  Future<List<Employee>> fetchAllEmployees() async {
    try {
      final uri = Uri.parse('$apiBaseUrl/get-all-employees');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch employees: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      dynamic body = decoded;
      if (decoded is Map && decoded.containsKey('body')) {
        body = decoded['body'];
        if (body is String) {
          body = jsonDecode(body);
        }
      }

      if (body is Map) {
        List<dynamic>? employeesJson;
        if (body.containsKey('employees')) {
          employeesJson = body['employees'];
        } else if (body.containsKey('Items')) {
          employeesJson = body['Items'];
        } else if (body.containsKey('users')) {
          employeesJson = body['users'];
        }

        if (employeesJson != null) {
          return employeesJson
              .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (body is List) {
        return body.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
      }

      throw Exception("AWS returned unknown structure. Raw body: $body");
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> submitManualAttendance({
    required String userId,
    required String date,
    required String time,
    required String status,
  }) async {
    final timestamp = DateTime.now().toIso8601String().split('.')[0]; // Clean format: 2026-03-29T14:28:24
    
    final resp = await http.post(
      Uri.parse('$apiBaseUrl/manual-attendance'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'timestamp': timestamp, 
        'status': status,
        'device': 'admin',
        'type': 'manual',
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to submit manual attendance: ${resp.body}');
    }

    final Map<String, dynamic> responseData = jsonDecode(resp.body);
    if (responseData.containsKey('errorMessage') || responseData.containsKey('errorType')) {
      throw Exception('Backend Error: ${responseData['errorMessage']}');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchAttendanceAnalytics() async {
    final resp = await http.get(
      Uri.parse('$apiBaseUrl/attendance-stats'),
      headers: {
        'Accept': 'application/json',
      },
    );

    print('DEBUG: fetchAttendanceAnalytics Status: ${resp.statusCode}');
    print('DEBUG: fetchAttendanceAnalytics Body: ${resp.body}');

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch analytics: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map && decoded.containsKey('body')) {
      final body = decoded['body'];
      return body is String ? jsonDecode(body) : body;
    }
    return decoded;
  }

  @override
  Future<void> deleteEmployee(String userId) async {
    final resp = await http.post(
      Uri.parse('$apiBaseUrl/delete-user'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': userId}), // The Lambda uses 'username' key for the 'user_id'
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete user: ${resp.body}');
    }
  }
}
