class IncomeModel {
  final int id;
  final double amount;
  final String description;
  final int? categoryId;
  final String categoryName;
  final String date;

  IncomeModel({
    required this.id,
    required this.amount,
    required this.description,
    this.categoryId,
    required this.categoryName,
    required this.date,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['income_id'] ?? json['id'] ?? 0,
      amount: double.parse(json['amount'].toString()),
      description: json['description'] ?? '',
      categoryId: json['category_id'] ?? json['categoryId'],
      categoryName: json['category_name'] ?? json['categoryName'] ?? 'Uncategorized',
      date: json['date'] is String
          ? (json['date'] as String).substring(0, 10)
          : json['date'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "amount": amount,
      "description": description,
      if (categoryId != null) "categoryId": categoryId,
      "date": date,
    };
  }
}