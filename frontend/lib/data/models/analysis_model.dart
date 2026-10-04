import 'barcode_model.dart';
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

class ConfidenceBreakdownModel {
  final double foodConfidence;
  final double portionConfidence;
  final double nutritionConfidence;
  final double overallConfidence;

  const ConfidenceBreakdownModel({
    required this.foodConfidence,
    required this.portionConfidence,
    required this.nutritionConfidence,
    required this.overallConfidence,
  });

  factory ConfidenceBreakdownModel.fromJson(Map<String, dynamic> json) {
    return ConfidenceBreakdownModel(
      foodConfidence: (json['food_confidence'] as num?)?.toDouble() ?? 0.0,
      portionConfidence: (json['portion_confidence'] as num?)?.toDouble() ?? 0.0,
      nutritionConfidence: (json['nutrition_confidence'] as num?)?.toDouble() ?? 0.0,
      overallConfidence: (json['overall_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VerificationDetailModel {
  final double finalCalories;
  final double originalCalories;
  final double macroDerivedCalories;
  final String verificationStatus; // verified, verified_with_warning, corrected, low_confidence, needs_confirmation
  final double confidenceScore;
  final ConfidenceBreakdownModel confidenceBreakdown;
  final List<String> verificationSources;
  final Map<String, double> sourceBreakdown;
  final double discrepancyPercent;
  final String verificationNote;
  final List<String> anomalyFlags;

  const VerificationDetailModel({
    required this.finalCalories,
    required this.originalCalories,
    required this.macroDerivedCalories,
    required this.verificationStatus,
    required this.confidenceScore,
    required this.confidenceBreakdown,
    required this.verificationSources,
    required this.sourceBreakdown,
    required this.discrepancyPercent,
    required this.verificationNote,
    required this.anomalyFlags,
  });

  factory VerificationDetailModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['source_breakdown'] as Map<String, dynamic>? ?? {};
    final sourcesMap = rawSources.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return VerificationDetailModel(
      finalCalories: (json['final_calories'] as num?)?.toDouble() ?? 0.0,
      originalCalories: (json['original_calories'] as num?)?.toDouble() ?? 0.0,
      macroDerivedCalories: (json['macro_derived_calories'] as num?)?.toDouble() ?? 0.0,
      verificationStatus: json['verification_status'] as String? ?? 'verified',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      confidenceBreakdown: json['confidence_breakdown'] != null
          ? ConfidenceBreakdownModel.fromJson(json['confidence_breakdown'] as Map<String, dynamic>)
          : const ConfidenceBreakdownModel(foodConfidence: 0, portionConfidence: 0, nutritionConfidence: 0, overallConfidence: 0),
      verificationSources: (json['verification_sources'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sourceBreakdown: sourcesMap,
      discrepancyPercent: (json['discrepancy_percent'] as num?)?.toDouble() ?? 0.0,
      verificationNote: json['verification_note'] as String? ?? '',
      anomalyFlags: (json['anomaly_flags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class MealItemAnalysisModel {
  String name;
  double quantity;
  String unit;
  double estimatedCalories;
  double? originalCalories;
  double? finalCalories;
  double protein;
  double carbohydrates;
  double fat;
  double fiber;
  double? confidence;
  bool matched;
  String? matchedFoodId;
  BoundingBoxModel? boundingBox;
  VerificationDetailModel? verification;
  bool isComponent;
  String? parentFood;
  double referenceServingSize;
  String referenceServingUnit;
  double? referenceCaloriesPer100g;
  double? referenceProteinPer100g;
  double? referenceCarbsPer100g;
  double? referenceFatPer100g;
  double? referenceFiberPer100g;

  MealItemAnalysisModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.estimatedCalories,
    this.originalCalories,
    this.finalCalories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    this.confidence,
    this.matched = false,
    this.matchedFoodId,
    this.boundingBox,
    this.verification,
    this.isComponent = false,
    this.parentFood,
    this.referenceServingSize = 100.0,
    this.referenceServingUnit = 'g',
    this.referenceCaloriesPer100g,
    this.referenceProteinPer100g,
    this.referenceCarbsPer100g,
    this.referenceFatPer100g,
    this.referenceFiberPer100g,
  });

  factory MealItemAnalysisModel.fromJson(Map<String, dynamic> json) {
    return MealItemAnalysisModel(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      estimatedCalories: (json['estimated_calories'] as num).toDouble(),
      originalCalories: (json['original_calories'] as num?)?.toDouble(),
      finalCalories: (json['final_calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble(),
      matched: json['matched'] as bool? ?? false,
      matchedFoodId: json['matched_food_id'] as String?,
      boundingBox: json['bounding_box'] != null
          ? BoundingBoxModel.fromJson(json['bounding_box'] as Map<String, dynamic>)
          : null,
      verification: json['verification'] != null
          ? VerificationDetailModel.fromJson(json['verification'] as Map<String, dynamic>)
          : null,
      isComponent: json['is_component'] as bool? ?? false,
      parentFood: json['parent_food'] as String?,
      referenceServingSize: (json['reference_serving_size'] as num?)?.toDouble() ?? 100.0,
      referenceServingUnit: json['reference_serving_unit'] as String? ?? 'g',
      referenceCaloriesPer100g: (json['reference_calories_per_100g'] as num?)?.toDouble(),
      referenceProteinPer100g: (json['reference_protein_per_100g'] as num?)?.toDouble(),
      referenceCarbsPer100g: (json['reference_carbs_per_100g'] as num?)?.toDouble(),
      referenceFatPer100g: (json['reference_fat_per_100g'] as num?)?.toDouble(),
      referenceFiberPer100g: (json['reference_fiber_per_100g'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMealItemCreateJson() {
    return {
      'food_id': (matchedFoodId != null && matchedFoodId!.trim().isNotEmpty) ? matchedFoodId : null,
      'food_name': name,
      'quantity': quantity,
      'unit': unit,
      'calories': estimatedCalories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'confidence': confidence,
      'original_calories': originalCalories ?? verification?.originalCalories,
      'final_calories': finalCalories ?? verification?.finalCalories ?? estimatedCalories,
      'verification_status': verification?.verificationStatus,
      'verification_confidence': verification?.confidenceScore,
      'verification_sources': verification?.verificationSources,
      'verification_note': verification?.verificationNote,
    };
  }
}

class MealAnalysisResponseModel {
  final String status;
  final String validationType;
  final double validationConfidence;
  final String? validationMessage;
  final BarcodeProductModel? barcodeProduct;
  final NutritionSummaryModel total;
  final List<MealItemAnalysisModel> items;
  final List<String> unmatchedItems;
  final String? imageUrl;
  final String verificationStatus;
  final List<String> warnings;
  final String disclaimer;

  MealAnalysisResponseModel({
    this.status = 'success',
    this.validationType = 'food',
    this.validationConfidence = 1.0,
    this.validationMessage,
    this.barcodeProduct,
    required this.total,
    required this.items,
    this.unmatchedItems = const [],
    this.imageUrl,
    this.verificationStatus = 'verified',
    this.warnings = const [],
    required this.disclaimer,
  });

  bool get isNonFood => status == 'non_food' || validationType == 'non_food';
  bool get isUncertain => status == 'uncertain' || validationType == 'uncertain';
  bool get isBarcode => status == 'barcode' || validationType == 'barcode';
  bool get isSuccess => status == 'success' && !isNonFood && !isUncertain && !isBarcode;

  factory MealAnalysisResponseModel.fromJson(Map<String, dynamic> json) {
    return MealAnalysisResponseModel(
      status: json['status'] as String? ?? 'success',
      validationType: json['validation_type'] as String? ?? 'food',
      validationConfidence: (json['validation_confidence'] as num?)?.toDouble() ?? 1.0,
      validationMessage: json['validation_message'] as String?,
      barcodeProduct: json['barcode_product'] != null
          ? BarcodeProductModel.fromJson(json['barcode_product'] as Map<String, dynamic>)
          : null,
      total: json['total'] != null
          ? NutritionSummaryModel.fromJson(json['total'] as Map<String, dynamic>)
          : NutritionSummaryModel(
              estimatedCalories: 0,
              protein: 0,
              carbohydrates: 0,
              fat: 0,
              fiber: 0,
            ),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MealItemAnalysisModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unmatchedItems: (json['unmatched_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: json['image_url'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'verified',
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
