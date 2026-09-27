import 'analysis_model.dart';

class FavoriteItemModel {
  final String? foodId;
  final String foodName;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;

  const FavoriteItemModel({
    this.foodId,
    required this.foodName,
    required this.quantity,
    this.unit = 'g',
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
  });

  factory FavoriteItemModel.fromJson(Map<String, dynamic> json) {
    return FavoriteItemModel(
      foodId: json['food_id'] as String?,
      foodName: json['food_name'] as String? ?? 'Food item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 100.0,
      unit: json['unit'] as String? ?? 'g',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
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
    };
  }

  MealItemAnalysisModel toMealItemAnalysis() {
    return MealItemAnalysisModel(
      name: foodName,
      quantity: quantity,
      unit: unit,
      estimatedCalories: calories,
      protein: protein,
      carbohydrates: carbohydrates,
      fat: fat,
      fiber: fiber,
      confidence: 1.0,
      matchedFoodId: foodId,
    );
  }
}

class FavoriteModel {
  final String id;
  final String userId;
  final String name;
  final String mealType;
  final List<FavoriteItemModel> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbohydrates;
  final double totalFat;
  final double totalFiber;
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.name,
    this.mealType = 'snack',
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbohydrates,
    required this.totalFat,
    required this.totalFiber,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items_json'] as List<dynamic>? ?? [];
    return FavoriteModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Favorite Meal',
      mealType: json['meal_type'] as String? ?? 'snack',
      items: rawItems.map((e) => FavoriteItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: (json['total_protein'] as num?)?.toDouble() ?? 0.0,
      totalCarbohydrates: (json['total_carbohydrates'] as num?)?.toDouble() ?? 0.0,
      totalFat: (json['total_fat'] as num?)?.toDouble() ?? 0.0,
      totalFiber: (json['total_fiber'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  List<MealItemAnalysisModel> toMealItemAnalysisList() {
    return items.map((i) => i.toMealItemAnalysis()).toList();
  }
}

