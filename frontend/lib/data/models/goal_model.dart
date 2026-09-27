class GoalModel {
  final String id;
  final String userId;
  final double calorieTarget;
  final double proteinTarget;
  final double carbohydratesTarget;
  final double fatTarget;
  final double fiberTarget;
  final double waterTargetMl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbohydratesTarget,
    required this.fatTarget,
    required this.fiberTarget,
    this.waterTargetMl = 2500.0,
    this.createdAt,
    this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      calorieTarget: (json['calorie_target'] as num).toDouble(),
      proteinTarget: (json['protein_target'] as num).toDouble(),
      carbohydratesTarget: (json['carbohydrates_target'] as num).toDouble(),
      fatTarget: (json['fat_target'] as num).toDouble(),
      fiberTarget: (json['fiber_target'] as num).toDouble(),
      waterTargetMl: json['water_target_ml'] != null
          ? (json['water_target_ml'] as num).toDouble()
          : 2500.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calorie_target': calorieTarget,
      'protein_target': proteinTarget,
      'carbohydrates_target': carbohydratesTarget,
      'fat_target': fatTarget,
      'fiber_target': fiberTarget,
      'water_target_ml': waterTargetMl,
    };
  }
}

class DailyAnalyticsModel {
  final String date;
  final double consumedCalories;
  final double consumedProtein;
  final double consumedCarbohydrates;
  final double consumedFat;
  final double consumedFiber;
  final double calorieProgress;
  final double proteinProgress;
  final double carbohydratesProgress;
  final double fatProgress;
  final double fiberProgress;
  final int mealsCount;
  final GoalModel goal;

  DailyAnalyticsModel({
    required this.date,
    required this.consumedCalories,
    required this.consumedProtein,
    required this.consumedCarbohydrates,
    required this.consumedFat,
    required this.consumedFiber,
    required this.calorieProgress,
    required this.proteinProgress,
    required this.carbohydratesProgress,
    required this.fatProgress,
    required this.fiberProgress,
    required this.mealsCount,
    required this.goal,
  });

  factory DailyAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return DailyAnalyticsModel(
      date: json['date'] as String,
      consumedCalories: (json['consumed_calories'] as num).toDouble(),
      consumedProtein: (json['consumed_protein'] as num).toDouble(),
      consumedCarbohydrates: (json['consumed_carbohydrates'] as num).toDouble(),
      consumedFat: (json['consumed_fat'] as num).toDouble(),
      consumedFiber: (json['consumed_fiber'] as num).toDouble(),
      calorieProgress: (json['calorie_progress'] as num).toDouble(),
      proteinProgress: (json['protein_progress'] as num).toDouble(),
      carbohydratesProgress: (json['carbohydrates_progress'] as num).toDouble(),
      fatProgress: (json['fat_progress'] as num).toDouble(),
      fiberProgress: (json['fiber_progress'] as num).toDouble(),
      mealsCount: json['meals_count'] as int,
      goal: GoalModel.fromJson(json['goal'] as Map<String, dynamic>),
    );
  }
}
