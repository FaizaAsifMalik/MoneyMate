class CategoryModel {
  final int id;
  final String name;
  final String type; // income or expense
  final String icon;
  final String? colour; // Hex color code

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.colour,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['category_id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      colour: json['colour'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "icon": icon,
      if (colour != null) "colour": colour,
    };
  }
}