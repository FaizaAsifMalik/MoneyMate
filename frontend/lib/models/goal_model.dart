class GoalModel {
  final int id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final String? deadline;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: (json['id'] ?? json['goal_id'] ?? 0) as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      targetAmount: _toDouble(json['targetAmount'] ?? json['target_amount']),
      savedAmount: _toDouble(json['savedAmount'] ?? json['saved_amount']),
      deadline: (json['deadline'] ?? json['end_date']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "targetAmount": targetAmount,
      "savedAmount": savedAmount,
      if (deadline != null) "deadline": deadline,
    };
  }
}