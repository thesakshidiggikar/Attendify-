import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class Employee {
  final String username;
  final String email;
  final String profile;
  final String faceId;
  final String cognitoUserId;
  // Placeholder for attendance status
  final String attendanceStatus;
  Employee({
    required this.username,
    required this.email,
    required this.profile,
    required this.faceId,
    required this.cognitoUserId,
    this.attendanceStatus = 'Not Marked',
  });
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profile: json['profile'] ?? '',
      faceId: json['FaceId'] ?? '',
      cognitoUserId: json['cognito_user_id'] ?? '',
      attendanceStatus: 'Not Marked', // Placeholder
    );
  }
}

class EmployeeRegistrationRepository {
  final String apiBaseUrl;
  EmployeeRegistrationRepository({required this.apiBaseUrl});

  Future<String> registerEmployee({
    required String username,
    required String email,
    required String password,
    required String profile,
    required XFile image,
  }) async {
    final imageBytes = await image.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    final registerResp = await http.post(
      Uri.parse('$apiBaseUrl/register-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'profile': profile,
        'image_base64': imageBase64,
      }),
    );
    if (registerResp.statusCode != 200) {
      throw Exception('Failed to register user: \n${registerResp.body}');
    }
    final registerData = jsonDecode(registerResp.body);
    dynamic userId;
    if (registerData.containsKey('body')) {
      final body = registerData['body'];
      try {
        final bodyJson = body is String ? jsonDecode(body) : body;
        if (bodyJson is Map && bodyJson.containsKey('message') && bodyJson['message'].toString().contains('User registered successfully')) {
          userId = bodyJson['FaceId'] ?? bodyJson['message'];
        }
      } catch (e) {
        userId = null;
      }
    } else {
      userId = registerData['userId'] ?? registerData['username'];
    }
    if (userId == null || userId is! String) {
      throw Exception('Registration failed: userId/username missing or invalid in response. Response: ${registerResp.body}');
    }
    return userId;
  }

  // Future<List<Employee>> fetchAllEmployees() async {
  //   final resp = await http.get(Uri.parse('$apiBaseUrl/get-all-employees'));
  //   if (resp.statusCode != 200) {
  //     throw Exception('Failed to fetch employees: ${resp.body}');
  //   }
  //   final data = jsonDecode(resp.body);
  //   final body = data['body'];
  //   final bodyJson = body is String ? jsonDecode(body) : body;
  //   final employeesJson = bodyJson['employees'] as List<dynamic>;
  //   return employeesJson.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  // }

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

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch employees: ${response.body}');
    }

    // Decode the top-level JSON
    final decoded = jsonDecode(response.body);

    // Decode the nested body string if needed
    dynamic body = decoded['body'];
    if (body is String) {
      body = jsonDecode(body);
    }

    // Check if employees key exists
    if (body is Map && body.containsKey('employees')) {
      final List<dynamic> employeesJson = body['employees'];
      return employeesJson
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Malformed response: 'employees' key missing");
    }
  } catch (e, st) {
    print('Error fetching employees: $e');
    print('Stacktrace: $st');
    rethrow;
  }
}


  Future<void> deleteEmployee(String username) async {
    final resp = await http.post(
      Uri.parse('$apiBaseUrl/delete-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete user: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    if (data is Map && data.containsKey('body')) {
      final body = data['body'];
      final bodyJson = body is String ? jsonDecode(body) : body;
      if (bodyJson is Map && bodyJson['message'] != null && bodyJson['message'].toString().contains('deleted successfully')) {
        return;
      }
    }
    throw Exception('Delete failed: ${resp.body}');
  }
} 