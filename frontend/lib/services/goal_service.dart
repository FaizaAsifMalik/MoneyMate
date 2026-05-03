import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goal_model.dart';
import 'api_service.dart';

class GoalService {
  static const String baseUrl = "https://money-mate-ub8a.vercel.app/api";

  static Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      if (ApiService.getToken() != null)
        "Authorization": "Bearer ${ApiService.getToken()}",
    };
  }

  /// Get all goals
  static Future<List<GoalModel>> getGoals() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/goals"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return (data['data'] as List)
          .map((e) => GoalModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch goals: $e");
    }
  }

  /// Get a single goal by ID
  static Future<GoalModel> getGoalById(int id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/goals/$id"),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      return GoalModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to fetch goal: $e");
    }
  }

  /// Create a new goal
  static Future<GoalModel> addGoal(GoalModel goal) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/goals"),
        headers: _headers(),
        body: jsonEncode(goal.toJson()),
      );
      final data = _handleResponse(response);
      return GoalModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to create goal: $e");
    }
  }

  /// Update a goal
  static Future<GoalModel> updateGoal(int id, Map<String, dynamic> fields) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/goals/$id"),
        headers: _headers(),
        body: jsonEncode(fields),
      );
      final data = _handleResponse(response);
      return GoalModel.fromJson(data['data']);
    } catch (e) {
      throw Exception("Failed to update goal: $e");
    }
  }

  /// Delete a goal
  static Future<void> deleteGoal(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/goals/$id"),
        headers: _headers(),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception("Failed to delete goal: $e");
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