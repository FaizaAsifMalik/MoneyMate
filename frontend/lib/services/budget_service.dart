import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BudgetService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Get all budgets
  static Future<List<Map<String, dynamic>>> getBudgets() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/budgets"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return (data['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Failed to fetch budgets: $e");
    }
  }

  /// Get a single budget by ID
  static Future<Map<String, dynamic>> getBudgetById(int id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/budgets/$id"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return data['data'];
    } catch (e) {
      throw Exception("Failed to fetch budget: $e");
    }
  }

  /// Create a new budget
  static Future<Map<String, dynamic>> createBudget({
    required int categoryId,
    required double limit,
    required String period,
    String? name,
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final y = now.year;
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final startDate = '$y-$m-$d';

      String endDate;
      if (period == 'weekly') {
        final end = now.add(const Duration(days: 7));
        endDate = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      } else if (period == 'yearly') {
        endDate = '${y + 1}-$m-$d';
      } else {
        // monthly
        final end = DateTime(y, now.month + 1, now.day);
        endDate = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      }

      final body = {
        "categoryId": categoryId,
        "limitAmount": limit,
        "period": period,
        "startDate": startDate,
        "endDate": endDate,
        if (name != null) "name": name,
        if (description != null) "description": description,
      };
      print('CREATE BUDGET BODY: $body');
      final response = await http.post(
        Uri.parse("$baseUrl/budgets"),
        headers: _headers(),
        body: jsonEncode(body),
      );
      print('CREATE BUDGET RESPONSE: ${response.statusCode} ${response.body}');
      final data = _handleResponse(response);
      return data['data'];
    } catch (e) {
      throw Exception("Failed to create budget: $e");
    }
  }

  /// Update a budget
  static Future<Map<String, dynamic>> updateBudget(
    int id, {
    double? limit,
    String? period,
    String? name,
    String? description,
  }) async {
    try {
      final body = {
        if (limit != null) "limitAmount": limit,
        if (period != null) "period": period,
        if (name != null) "name": name,
        if (description != null) "description": description,
      };
      print('UPDATE BUDGET BODY: $body');
      final response = await http.put(
        Uri.parse("$baseUrl/budgets/$id"),
        headers: _headers(),
        body: jsonEncode(body),
      );
      print('UPDATE BUDGET RESPONSE: ${response.statusCode} ${response.body}');
      final data = _handleResponse(response);
      return data['data'];
    } catch (e) {
      throw Exception("Failed to update budget: $e");
    }
  }

  /// Delete a budget
  static Future<void> deleteBudget(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/budgets/$id"),
        headers: _headers(),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to delete budget: $e");
    }
  }

  /// Get budget alert (check if exceeded)
  static Future<Map<String, dynamic>> checkBudgetAlert(int budgetId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/budgets/$budgetId/alert"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return data['data'] ?? data;
    } catch (e) {
      throw Exception("Failed to check budget alert: $e");
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