import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static String? _token;

  /// Set the JWT token (usually after login)
  static void setToken(String token) {
    _token = token;
  }

  /// Get the current token
  static String? getToken() => _token;

  /// Clear the token (usually on logout)
  static void clearToken() {
    _token = null;
  }

  /// Standard headers with authorization
  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }

  /// GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$endpoint"),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception("GET $endpoint failed: $e");
    }
  }

  /// POST request
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/$endpoint"),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception("POST $endpoint failed: $e");
    }
  }

  /// PUT request
  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$endpoint"),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception("PUT $endpoint failed: $e");
    }
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/$endpoint"),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception("DELETE $endpoint failed: $e");
    }
  }

  /// Handle HTTP response and parse JSON
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // Extract error message from response
      final message = data['message'] ?? 'Unknown error occurred';
      throw Exception("HTTP ${response.statusCode}: $message");
    }
  }
}