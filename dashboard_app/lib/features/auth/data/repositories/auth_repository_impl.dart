import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String baseUrl = 'https://wny1io6xre.execute-api.ap-south-1.amazonaws.com/dev';
  
  AuthRepositoryImpl();

  String _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      
      // Decode the payload (second part)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return resp;
    } catch (e) {
      print('Error decoding JWT: $e');
      return '';
    }
  }

  @override
  Future<UserModel> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }

    final responseData = jsonDecode(response.body);
    
    // Handle nested JSON in 'body' field (same pattern as registration)
    dynamic bodyData;
    if (responseData.containsKey('body')) {
      final body = responseData['body'];
      bodyData = body is String ? jsonDecode(body) : body;
    } else {
      bodyData = responseData;
    }
    
    final accessToken = bodyData['accessToken'] ?? '';
    final idToken = bodyData['idToken'] ?? '';
    
    // Decode the JWT to get user profile
    String userRole = 'employee'; // default
    String userId = username; // default
    
    if (idToken.isNotEmpty) {
      final payload = _decodeJwtPayload(idToken);
      if (payload.isNotEmpty) {
        final tokenData = jsonDecode(payload);
        userRole = tokenData['profile'] ?? 'employee';
        userId = tokenData['sub'] ?? username;
      }
    }
    
    return UserModel(
      id: userId,
      name: username,
      role: userRole,
      token: accessToken,
    );
  }

  @override
  Future<UserModel> getCurrentUser() async {
    throw UnimplementedError('getCurrentUser not implemented yet');
  }
} 