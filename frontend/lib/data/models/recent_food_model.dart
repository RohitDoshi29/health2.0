class RecentFoodModel {
  final String? foodId;
  final String foodName;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final DateTime lastLoggedAt;

  const RecentFoodModel({
    this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.lastLoggedAt,
  });

  factory RecentFoodModel.fromJson(Map<String, dynamic> json) {
    return RecentFoodModel(
      foodId: json['food_id'] as String?,
      foodName: json['food_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'g',
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      lastLoggedAt: DateTime.parse(json['last_logged_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'food_name': foodName,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'last_logged_at': lastLoggedAt.toIso8601String(),
    };
  }
}
