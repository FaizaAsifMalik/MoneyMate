class ExpenseModel {
  final int id;
  final double amount;
  final String description;
  final int? categoryId; // nullable — category may not always be set
  final String date;

  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColour;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.description,
    this.categoryId,
    required this.date,
    this.categoryName,
    this.categoryIcon,
    this.categoryColour,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['expense_id'],
      amount: double.parse(json['amount'].toString()),
      description: json['description'] ?? '',
      categoryId: json['category_id'],
      date: json['date'],
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
      categoryColour: json['category_colour'],
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