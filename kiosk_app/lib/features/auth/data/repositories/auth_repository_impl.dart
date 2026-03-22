import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://wny1io6xre.execute-api.ap-south-1.amazonaws.com/dev';
  
  AuthRepositoryImpl();

  String _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return resp;
    } catch (e) {
      return '';
    }
  }

  @override
  Future<UserModel> login(String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': userId,
        'password': password,
      }),
    );

    print('DEBUG: Kiosk Login Status: ${response.statusCode}');
    print('DEBUG: Kiosk Login Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }

    final responseData = jsonDecode(response.body);
    dynamic bodyData;
    if (responseData.containsKey('body')) {
      final body = responseData['body'];
      bodyData = body is String ? jsonDecode(body) : body;
    } else {
      bodyData = responseData;
    }

    if (bodyData['challengeName'] == 'NEW_PASSWORD_REQUIRED') {
      throw Exception('NEW_PASSWORD_REQUIRED');
    }
    
    final accessToken = bodyData['accessToken'] ?? '';
    final idToken = bodyData['idToken'] ?? '';
    
    String userRole = 'student';
    String finalUserId = userId; // Use parameter userId
    
    if (idToken.isNotEmpty) {
      final payload = _decodeJwtPayload(idToken);
      if (payload.isNotEmpty) {
        final tokenData = jsonDecode(payload);
        userRole = tokenData['profile'] ?? 'student';
        finalUserId = tokenData['sub'] ?? userId;
      }
    }
    
    return UserModel(
      id: finalUserId,
      name: userId, // Using userId as name since it's the student ID provided
      role: userRole,
      token: accessToken,
    );
  }

  @override
  Future<void> logout() async {
    // Implement token clearing if needed
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return null; // TODO: Implement persistent login
  }

  Future<UserModel> confirmNewPassword(String username, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/confirm-new-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update password: ${response.body}');
    }
    return login(username, newPassword);
  }
}
