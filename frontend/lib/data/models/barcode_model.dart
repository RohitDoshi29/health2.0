import 'analysis_model.dart';

class BarcodeProductModel {
  final String barcode;
  final String name;
  final String? brand;
  final String? servingSize;
  final double servingQuantity;
  final String servingUnit;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double? sugars;
  final double? sodium;
  final String? nutriscoreGrade;
  final int? novaGroup;
  final String? imageUrl;
  final String? ingredients;
  final String source;

  const BarcodeProductModel({
    required this.barcode,
    required this.name,
    this.brand,
    this.servingSize,
    required this.servingQuantity,
    this.servingUnit = 'g',
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    this.sugars,
    this.sodium,
    this.nutriscoreGrade,
    this.novaGroup,
    this.imageUrl,
    this.ingredients,
    this.source = 'openfoodfacts',
  });

  factory BarcodeProductModel.fromJson(Map<String, dynamic> json) {
    return BarcodeProductModel(
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String? ?? 'Packaged Food',
      brand: json['brand'] as String?,
      servingSize: json['serving_size'] as String?,
      servingQuantity: (json['serving_quantity'] as num?)?.toDouble() ?? 100.0,
      servingUnit: json['serving_unit'] as String? ?? 'g',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sugars: (json['sugars'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      nutriscoreGrade: json['nutriscore_grade'] as String?,
      novaGroup: (json['nova_group'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
      ingredients: json['ingredients'] as String?,
      source: json['source'] as String? ?? 'openfoodfacts',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'serving_size': servingSize,
      'serving_quantity': servingQuantity,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugars': sugars,
      'sodium': sodium,
      'nutriscore_grade': nutriscoreGrade,
      'nova_group': novaGroup,
      'image_url': imageUrl,
      'ingredients': ingredients,
      'source': source,
    };
  }

  /// Converts this product to a MealItemAnalysisModel scaled by a portion multiplier.
  MealItemAnalysisModel toMealItemAnalysis({double multiplier = 1.0}) {
    final qty = (servingQuantity * multiplier).roundToDouble();
    final itemDisplayName = brand != null && brand!.isNotEmpty ? '$name ($brand)' : name;

    return MealItemAnalysisModel(
      name: itemDisplayName,
      quantity: qty > 0 ? qty : 1.0,
      unit: servingUnit.isNotEmpty ? servingUnit : 'g',
      estimatedCalories: (calories * multiplier).roundToDouble(),
      protein: double.parse((protein * multiplier).toStringAsFixed(1)),
      carbohydrates: double.parse((carbohydrates * multiplier).toStringAsFixed(1)),
      fat: double.parse((fat * multiplier).toStringAsFixed(1)),
      fiber: double.parse((fiber * multiplier).toStringAsFixed(1)),
      confidence: 1.0,
    );
  }
}

