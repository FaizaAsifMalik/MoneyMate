import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService {
  static String get baseUrl => ApiService.baseUrl;

  /// Register a new user
static Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
  String currency = "PKR",
}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "currency": currency,
      }),
    );

    final data = _handleResponse(response);

    final token = data['data']?['token'];
    if (token != null) {
      ApiService.setToken(token);
    }

    return data;
  }
  
  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = _handleResponse(response);

      final token = data['token'] ?? data['data']?['token'];
      if (token != null) {
        ApiService.setToken(token);
        data['token'] = token;
        data['success'] = true;
      }

      return data;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  /// OTP
  static Future<Map<String, dynamic>> sendOtp({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to send OTP: $e");
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception("Password reset failed: $e");
    }
  }

  /// Logout
  static void logout() {
    ApiService.clearToken();
  }

  /// Auth check
  static bool isAuthenticated() {
    return ApiService.getToken() != null;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      final message = data['message'] ?? 'Unknown error occurred';
      throw Exception("HTTP ${response.statusCode}: $message");
    }
  }
}
