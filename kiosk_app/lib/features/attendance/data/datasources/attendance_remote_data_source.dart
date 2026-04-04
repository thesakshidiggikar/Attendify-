import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/foundation.dart';

class AttendanceRemoteDataSource {
  String get baseUrl {
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
      'image': base64Image, // Match registration key 'image'
    };
    if (machineId != null) {
      body['device'] = machineId;
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('DEBUG: mark_attendance status=${response.statusCode}');
    print('DEBUG: mark_attendance body=${response.body}');

    if (response.statusCode != 200) {
      // Try to parse error message from body
      try {
        final errDecoded = jsonDecode(response.body);
        final errBody = errDecoded is Map && errDecoded.containsKey('body') 
            ? (errDecoded['body'] is String ? jsonDecode(errDecoded['body']) : errDecoded['body'])
            : errDecoded;
        throw Exception(errBody['message'] ?? errBody['error'] ?? 'Failed to mark attendance');
      } catch (e) {
        throw Exception('Failed to mark attendance: ${response.statusCode}');
      }
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
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        dynamic bodyData;
        if (data is Map && data.containsKey('body')) {
          final b = data['body'];
          bodyData = b is String ? jsonDecode(b) : b;
        } else {
          bodyData = data;
        }

        print('DEBUG: fetchRecentAttendance bodyData type=${bodyData.runtimeType}');
        if (bodyData is! Map) {
          print('DEBUG: fetchRecentAttendance error: bodyData is not a Map, it is $bodyData');
          return [];
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