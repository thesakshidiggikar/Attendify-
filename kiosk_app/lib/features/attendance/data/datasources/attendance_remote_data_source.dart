import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/foundation.dart';

class AttendanceRemoteDataSource {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000'; // local CORS proxy
    }
    return dotenv.env['API_BASE_URL'] ??
        'https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default';
  }

  /// Sends the captured face image to the backend for recognition + attendance marking.
  /// Returns a Map with student info: { 'name': '...', 'user_id': '...', 'message': '...' }
  Future<Map<String, dynamic>> uploadAttendanceImage(
    String base64Image, {
    String? machineId,
  }) async {
    final url = Uri.parse('$baseUrl/mark_attendance');
    final body = <String, dynamic>{
      'image_bytes': base64Image,
    };
    if (machineId != null) {
      body['device'] = machineId;
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('DEBUG: mark_attendance status=${response.statusCode}');
    print('DEBUG: mark_attendance body=${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to mark attendance: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    // Handle API Gateway wrapped response
    dynamic bodyData;
    if (decoded is Map && decoded.containsKey('body')) {
      final b = decoded['body'];
      bodyData = b is String ? jsonDecode(b) : b;
    } else {
      bodyData = decoded;
    }

    // Extract student name from various possible response formats
    final String studentName = bodyData['name'] ??
        bodyData['full_name'] ??
        bodyData['student_name'] ??
        bodyData['user_name'] ??
        bodyData['username'] ??
        bodyData['user_id'] ??
        'Unknown Student';

    final String userId = bodyData['user_id'] ??
        bodyData['username'] ??
        bodyData['student_id'] ??
        '';

    final String message = bodyData['message'] ?? 'Attendance marked';

    return {
      'name': studentName,
      'user_id': userId,
      'message': message,
      'raw': bodyData,
    };
  }

  /// Fetch recent attendance entries for the kiosk (all students on this machine today)
  Future<List<Map<String, dynamic>>> fetchRecentAttendance({
    String? machineId,
  }) async {
    final queryParams = machineId != null ? '?device=$machineId' : '';
    final url = Uri.parse('$baseUrl/recent-attendance$queryParams');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        dynamic bodyData;
        if (data is Map && data.containsKey('body')) {
          final b = data['body'];
          bodyData = b is String ? jsonDecode(b) : b;
        } else {
          bodyData = data;
        }

        final List<dynamic> recent =
            bodyData['recent_attendance'] ?? bodyData['records'] ?? [];
        return recent.map<Map<String, dynamic>>((e) {
          return {
            'user_id': e['user_id'] ?? e['username'] ?? '',
            'name': e['name'] ?? e['full_name'] ?? e['user_id'] ?? 'Unknown',
            'timestamp': e['timestamp'] ?? '',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('DEBUG: fetchRecentAttendance error: $e');
      return [];
    }
  }
}