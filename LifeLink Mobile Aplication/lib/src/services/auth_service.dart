import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ──────────────────────────────────────────────────────────────
  // IMPORTANT: Change this before running on real phone
  // 1. Android emulator → keep '10.0.2.2'
  // 2. Real phone     → your computer's real IPv4 (run ipconfig)
  // ──────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.168.30.196:3000'; // ← change this!

  // Optional: add timeout to prevent hanging forever
  static const int requestTimeoutSeconds = 10;

  // Token key - keep as jwt_token for compatibility with existing pages
  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _nameKey = 'user_name';
  static const String _userIdKey = 'user_id';

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/login');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: requestTimeoutSeconds));

      print('Login status: ${response.statusCode}');
      print('Login body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();

          // Keep using jwt_token for compatibility
          await prefs.setString(_tokenKey, data['token']);
          await prefs.setString(_roleKey, data['role']);
          await prefs.setString(_nameKey, data['name'] ?? 'User');

          print('✅ Token saved with key: $_tokenKey');
          print(
              '✅ Token preview: ${data['token'].substring(0, data['token'].length > 20 ? 20 : data['token'].length)}...');

          return {
            'success': true,
            'role': data['role'],
            'token': data['token'],
            'name': data['name'],
          };
        } else {
          print('Server said: ${data['error'] ?? 'No success flag'}');
        }
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e) {
      print('Login network error: $e');
      return null;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_userIdKey);
    print('🔓 Auth data cleared');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }
}
