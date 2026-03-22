import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this line

class AttendanceRemoteDataSource {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://wny1io6xre.execute-api.ap-south-1.amazonaws.com/dev';

  Future<List<dynamic>> fetchRecentEntries(String userId) async {
    // TODO: Implement API call
    return [];
  }

  Future<void> uploadAttendanceImage(dynamic imageBytes) async {
    final url = Uri.parse('$baseUrl/mark_attendance');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_bytes': imageBytes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark attendance: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentAttendance({String? userId}) async {
    final url = Uri.parse('$baseUrl/recent-attendance${userId != null ? '?user_id=$userId' : ''}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> recent = data['recent_attendance'] ?? [];
      return recent.map<Map<String, dynamic>>((e) => {
        'user_id': e['user_id'] ?? e['username'] ?? '',
        'timestamp': e['timestamp'] ?? '',
      }).toList();
    } else {
      throw Exception('Failed to fetch recent attendance');
    }
  }
}