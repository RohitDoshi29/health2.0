import 'nutrition_model.dart';

class BoundingBoxModel {
  final double ymin;
  final double xmin;
  final double ymax;
  final double xmax;

  const BoundingBoxModel({
    required this.ymin,
    required this.xmin,
    required this.ymax,
    required this.xmax,
  });

  factory BoundingBoxModel.fromJson(Map<String, dynamic> json) {
    return BoundingBoxModel(
      ymin: (json['ymin'] as num).toDouble(),
      xmin: (json['xmin'] as num).toDouble(),
      ymax: (json['ymax'] as num).toDouble(),
      xmax: (json['xmax'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ymin': ymin,
      'xmin': xmin,
      'ymax': ymax,
      'xmax': xmax,
    };
  }
}

class MealItemAnalysisModel {
  String name;
  double quantity;
  String unit;
  double estimatedCalories;
  double protein;
  double carbohydrates;
  double fat;
  double fiber;
  double? confidence;
  String? matchedFoodId;
  BoundingBoxModel? boundingBox;

  MealItemAnalysisModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.estimatedCalories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    this.confidence,
    this.matchedFoodId,
    this.boundingBox,
  });

  factory MealItemAnalysisModel.fromJson(Map<String, dynamic> json) {
    return MealItemAnalysisModel(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      estimatedCalories: (json['estimated_calories'] as num).toDouble(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble(),
      matchedFoodId: json['matched_food_id'] as String?,
      boundingBox: json['bounding_box'] != null
          ? BoundingBoxModel.fromJson(json['bounding_box'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMealItemCreateJson() {
    return {
      'food_id': matchedFoodId,
      'food_name': name,
      'quantity': quantity,
      'unit': unit,
      'calories': estimatedCalories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'confidence': confidence,
    };
  }
}

class MealAnalysisResponseModel {
  final NutritionSummaryModel total;
  final List<MealItemAnalysisModel> items;
  final String? imageUrl;
  final String disclaimer;

  MealAnalysisResponseModel({
    required this.total,
    required this.items,
    this.imageUrl,
    required this.disclaimer,
  });

  factory MealAnalysisResponseModel.fromJson(Map<String, dynamic> json) {
    return MealAnalysisResponseModel(
      total: NutritionSummaryModel.fromJson(json['total'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => MealItemAnalysisModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['image_url'] as String?,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

