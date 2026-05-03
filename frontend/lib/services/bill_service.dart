import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BillService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Get all bills
  static Future<List<Map<String, dynamic>>> getBills({
    String? status, // 'pending', 'paid', 'overdue'
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (limit != null) params['limit'] = limit.toString();
      if (offset != null) params['offset'] = offset.toString();

      final uri =
          Uri.parse("$baseUrl/bills").replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers());
      
      final data = _handleResponse(response);
      return (data['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Failed to fetch bills: $e");
    }
  }

  /// Get a single bill by ID
  static Future<Map<String, dynamic>> getBillById(int id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/bills/$id"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return data['data'];
    } catch (e) {
      throw Exception("Failed to fetch bill: $e");
    }
  }

  /// Create a new bill
  /// [dueDate] is the day of the month (1–31)
  /// [nextDueDate] is the next actual due date in ISO format (e.g. 2026-05-14)
  /// [frequency] is 'monthly' or 'yearly'
  static Future<Map<String, dynamic>> createBill({
    required String name,
    required double amount,
    required int dueDate,
    required String frequency,
    required String nextDueDate,
    int? categoryId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/bills"),
        headers: _headers(),
        body: jsonEncode({
          "name": name,
          "amount": amount,
          "dueDate": dueDate,
          "frequency": frequency,
          "nextDueDate": nextDueDate,
          if (categoryId != null) "categoryId": categoryId,
        }),
      );
      final data = _handleResponse(response);
      return data['data'];
    } catch (e) {
      throw Exception("Failed to create bill: $e");
    }
  }

  /// Update a bill
  /// [dueDate] is the day of the month (1–31)
  /// [nextDueDate] is the next actual due date in ISO format (e.g. 2026-05-14)
  static Future<Map<String, dynamic>> updateBill(
    int id, {
    String? name,
    double? amount,
    int? dueDate,
    String? nextDueDate,
    String? frequency,
    bool? isPaid,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/bills/$id"),
        headers: _headers(),
        body: jsonEncode({
          if (name != null) "name": name,
          if (amount != null) "amount": amount,
          if (dueDate != null) "dueDate": dueDate,
          if (nextDueDate != null) "nextDueDate": nextDueDate,
          if (frequency != null) "frequency": frequency,
          if (isPaid != null) "isPaid": isPaid,
        }),
      );
      final data = _handleResponse(response);
      return data['data'];
    } catch (e) {
      throw Exception("Failed to update bill: $e");
    }
  }

  /// Delete a bill
  static Future<void> deleteBill(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/bills/$id"),
        headers: _headers(),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to delete bill: $e");
    }
  }

  /// Mark a bill as paid
  static Future<Map<String, dynamic>> markAsPaid(int id) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/bills/$id/pay"),
        headers: _headers(),
        body: jsonEncode({"status": "paid"}),
      );
      final data = _handleResponse(response);
      return data['data'];
    } catch (e) {
      throw Exception("Failed to mark bill as paid: $e");
    }
  }

  /// Get upcoming bills
  static Future<List<Map<String, dynamic>>> getUpcomingBills({
    int days = 30,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/bills/upcoming")
          .replace(queryParameters: {"days": days.toString()});
      final response = await http.get(uri, headers: _headers());

      final data = _handleResponse(response);
      return (data['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Failed to fetch upcoming bills: $e");
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