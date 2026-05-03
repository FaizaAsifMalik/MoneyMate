import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AIService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Deep-casts a Map with dynamic keys to Map<String, dynamic>
  static Map<String, dynamic> _safeCast(Map m) =>
      m.map((k, v) => MapEntry(k.toString(), v));

  /// If a value looks like a number string, convert it to num
  static dynamic _parseNum(dynamic v) {
    if (v is String) {
      final parsed = num.tryParse(v);
      if (parsed != null) return parsed;
    }
    return v;
  }

  /// Converts all string-number values in a flat map to actual num
  static Map<String, dynamic> _parseNumericFields(Map<String, dynamic> m) {
    return m.map((k, v) => MapEntry(k, _parseNum(v)));
  }

  /// Get all AI insights — the only AI endpoint that exists.
  /// Returns { trends, budgetPredictions, suggestions, expenseSummary }
  static Future<Map<String, dynamic>> getInsights() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/ai/insights"),
        headers: _headers(),
      );

      final raw = _handleResponse(response);
      final data = raw['data'] != null
          ? _safeCast(raw['data'] as Map)
          : raw;

      // Fix budgetPredictions: cast keys + parse numeric strings
      if (data['budgetPredictions'] is Map) {
        data['budgetPredictions'] = _parseNumericFields(
          _safeCast(data['budgetPredictions'] as Map),
        );
      } else {
        data['budgetPredictions'] = <String, dynamic>{};
      }

      // Fix suggestions: must be List of Map<String, dynamic>
      if (data['suggestions'] is List) {
        data['suggestions'] = (data['suggestions'] as List).map((e) {
          if (e is Map) return _parseNumericFields(_safeCast(e));
          return <String, dynamic>{};
        }).toList();
      } else {
        data['suggestions'] = <Map<String, dynamic>>[];
      }

      // Fix expenseSummary: must be List of Map<String, dynamic>
      if (data['expenseSummary'] is List) {
        data['expenseSummary'] = (data['expenseSummary'] as List).map((e) {
          if (e is Map) return _parseNumericFields(_safeCast(e));
          return <String, dynamic>{};
        }).toList();
      } else {
        data['expenseSummary'] = <Map<String, dynamic>>[];
      }

      return data;
    } catch (e) {
      throw Exception("Failed to fetch AI insights: $e");
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    final data = _safeCast(decoded as Map);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      final message = data['message'] ?? 'Unknown error occurred';
      throw Exception("HTTP ${response.statusCode}: $message");
    }
  }
}