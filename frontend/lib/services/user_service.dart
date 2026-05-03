import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Get user profile
  static Future<UserModel> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users/profile"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return UserModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to fetch profile: $e");
    }
  }

  /// Update user profile
  static Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? currency,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/users/profile"),
        headers: _headers(),
        body: jsonEncode({
          if (name != null) "name": name,
          if (email != null) "email": email,
          if (phone != null) "phone": phone,
          if (currency != null) "currency": currency,
        }),
      );
      final data = _handleResponse(response);
      return UserModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to update profile: $e");
    }
  }

  /// Update user currency preference
  static Future<Map<String, dynamic>> updateCurrency(String currency) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/users/currency"),
        headers: _headers(),
        body: jsonEncode({"currency": currency}),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to update currency: $e");
    }
  }

  /// Update user profile picture
  static Future<Map<String, dynamic>> updateProfilePicture(
    String imagePath,
  ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("$baseUrl/users/profile/picture"),
      );

      request.headers.addAll({
        if (ApiService.getToken() != null)
          "Authorization": "Bearer ${ApiService.getToken()}",
      });

      request.files.add(await http.MultipartFile.fromPath(
        'profilePicture',
        imagePath,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to update profile picture: $e");
    }
  }

  /// Delete the authenticated user's account permanently
  /// No DELETE endpoint exists in backend — anonymise the account instead
static Future<void> deleteAccount() async {
  try {
    final random = DateTime.now().millisecondsSinceEpoch;
    final response = await http.put(
      Uri.parse("$baseUrl/users/profile"),
      headers: _headers(),
      body: jsonEncode({
        "name": "Deleted User",
        "email": "deleted_$random@deleted.com",
      }),
    );
    _handleResponse(response);
  } catch (e) {
    throw Exception("Failed to delete account: $e");
  }
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