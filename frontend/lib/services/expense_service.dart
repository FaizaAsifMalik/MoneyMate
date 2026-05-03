import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';
import 'api_service.dart';

class ExpenseService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Get all expenses with optional filters
  /// Supports filters: startDate, endDate, categoryId, limit, offset
  static Future<List<ExpenseModel>> getExpenses({
    String? startDate,
    String? endDate,
    int? categoryId,
    int? limit,
    int? offset,
  }) async {
    try {
      final query = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (categoryId != null) 'categoryId': categoryId.toString(),
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };

      final uri = Uri.parse("$baseUrl/expenses").replace(queryParameters: query);
      final response = await http.get(uri, headers: _headers());
      final data = _handleResponse(response);

      // Backend wraps list in { success: true, data: [...] }
      return (data['data'] as List)
          .map((e) => ExpenseModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch expenses: $e");
    }
  }

  /// Get a single expense by ID
  static Future<ExpenseModel> getExpenseById(int id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/expenses/$id"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return ExpenseModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to fetch expense: $e");
    }
  }

  /// Create a new expense
  /// Required fields: categoryId, amount, date
  /// Optional: description
  static Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/expenses"),
        headers: _headers(),
        body: jsonEncode(expense.toJson()),
      );
      final data = _handleResponse(response);
      return ExpenseModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to create expense: $e");
    }
  }

  /// Update an expense
  static Future<ExpenseModel> updateExpense(
      int id, Map<String, dynamic> fields) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/expenses/$id"),
        headers: _headers(),
        body: jsonEncode(fields),
      );
      final data = _handleResponse(response);
      return ExpenseModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to update expense: $e");
    }
  }

  /// Delete an expense
  static Future<void> deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/expenses/$id"),
        headers: _headers(),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to delete expense: $e");
    }
  }

  /// Get expense summary by category for a date range
  static Future<List<Map<String, dynamic>>> getSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse("$baseUrl/expenses/summary")
          .replace(queryParameters: query);
      final response = await http.get(uri, headers: _headers());
      final data = _handleResponse(response);

      return List<Map<String, dynamic>>.from(data['data']);
    } catch (e) {
      throw Exception("Failed to fetch summary: $e");
    }
  }

  /// Get monthly expense totals for last 6 months
  static Future<List<Map<String, dynamic>>> getMonthlyTotals() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/expenses/monthly"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['data']);
    } catch (e) {
      throw Exception("Failed to fetch monthly totals: $e");
    }
  }

  /// Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    final message = data['message'] ?? 'Unknown error';
    throw Exception("[${response.statusCode}] $message");
  }
}