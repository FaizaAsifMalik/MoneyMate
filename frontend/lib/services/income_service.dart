import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/income_model.dart';
import 'api_service.dart';

class IncomeService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Get all incomes with optional filters
  static Future<List<IncomeModel>> getIncomes({
    String? startDate,
    String? endDate,
    int? categoryId,
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      if (categoryId != null) params['categoryId'] = categoryId.toString();
      if (limit != null) params['limit'] = limit.toString();
      if (offset != null) params['offset'] = offset.toString();

      final uri =
          Uri.parse("$baseUrl/incomes").replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers());
      
      final data = _handleResponse(response);
      return (data['data'] as List)
          .map((e) => IncomeModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch incomes: $e");
    }
  }

  /// Get a single income by ID
  static Future<IncomeModel> getIncomeById(int id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/incomes/$id"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return IncomeModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to fetch income: $e");
    }
  }

  /// Create a new income
  static Future<IncomeModel> addIncome(IncomeModel income) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/incomes"),
        headers: _headers(),
        body: jsonEncode(income.toJson()),
      );
      final data = _handleResponse(response);
      return IncomeModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to create income: $e");
    }
  }

  /// Update an income
  static Future<IncomeModel> updateIncome(
      int id, Map<String, dynamic> fields) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/incomes/$id"),
        headers: _headers(),
        body: jsonEncode(fields),
      );
      final data = _handleResponse(response);
      return IncomeModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to update income: $e");
    }
  }

  /// Delete an income
  static Future<void> deleteIncome(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/incomes/$id"),
        headers: _headers(),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to delete income: $e");
    }
  }

  /// Get monthly income totals
  static Future<Map<String, dynamic>> getMonthlyTotals() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/incomes/monthly"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return data['data'] ?? data;
    } catch (e) {
      throw Exception("Failed to fetch monthly totals: $e");
    }
  }

  /// Get income summary
  static Future<Map<String, dynamic>> getSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;

      final uri =
          Uri.parse("$baseUrl/incomes/summary").replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers());

      final data = _handleResponse(response);
      return data['data'] ?? data;
    } catch (e) {
      throw Exception("Failed to fetch summary: $e");
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      final message = data is Map
          ? (data['message'] ?? data['error'] ?? 'Unknown error')
          : 'Unknown error';
      throw Exception("HTTP ${response.statusCode}: $message");
    }
  }
}