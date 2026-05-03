import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import 'api_service.dart';

class CategoryService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Get all categories (with optional type filter)
  static Future<List<CategoryModel>> getCategories({String? type}) async {
    try {
      final path = type != null ? "$baseUrl/categories/type/$type" : "$baseUrl/categories";
      final response = await http.get(Uri.parse(path), headers: _headers());

      final data = _handleResponse(response);
      
      // Backend wraps list in { success: true, data: [...] }
      return (data['data'] as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch categories: $e");
    }
  }

  /// Get a single category by ID
  static Future<CategoryModel> getCategoryById(int id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/categories/$id"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return CategoryModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to fetch category: $e");
    }
  }

  /// Create a new category
  static Future<CategoryModel> createCategory({
    required String name,
    required String type, // 'income' or 'expense'
    required String icon,
    String? colour,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/categories"),
        headers: _headers(),
        body: jsonEncode({
          "name": name,
          "type": type,
          "icon": icon,
          if (colour != null) "colour": colour,
        }),
      );
      final data = _handleResponse(response);
      return CategoryModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to create category: $e");
    }
  }

  /// Update a category
  static Future<CategoryModel> updateCategory(
    int id, {
    String? name,
    String? type,
    String? icon,
    String? colour,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/categories/$id"),
        headers: _headers(),
        body: jsonEncode({
          if (name != null) "name": name,
          if (type != null) "type": type,
          if (icon != null) "icon": icon,
          if (colour != null) "colour": colour,
        }),
      );
      final data = _handleResponse(response);
      return CategoryModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to update category: $e");
    }
  }

  /// Delete a category
  static Future<void> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/categories/$id"),
        headers: _headers(),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to delete category: $e");
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