import 'goal_model.dart';

class UserProfileModel {
  final String id;
  final String userId;
  final int age;
  final String sex;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;
  final bool onboardingCompleted;
  final double? bmr;
  final double? tdee;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.id,
    required this.userId,
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.onboardingCompleted,
    this.bmr,
    this.tdee,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      age: json['age'] as int,
      sex: json['sex'] as String,
      heightCm: (json['height_cm'] as num).toDouble(),
      weightKg: (json['weight_kg'] as num).toDouble(),
      activityLevel: json['activity_level'] as String,
      goal: json['goal'] as String,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      bmr: json['bmr'] != null ? (json['bmr'] as num).toDouble() : null,
      tdee: json['tdee'] != null ? (json['tdee'] as num).toDouble() : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'sex': sex,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel,
      'goal': goal,
    };
  }
}

class NutritionTargetsModel {
  final double bmr;
  final double tdee;
  final double calorieTarget;
  final double proteinTarget;
  final double carbohydratesTarget;
  final double fatTarget;
  final double fiberTarget;
  final double waterTargetMl;

  NutritionTargetsModel({
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbohydratesTarget,
    required this.fatTarget,
    required this.fiberTarget,
    required this.waterTargetMl,
  });

  factory NutritionTargetsModel.fromJson(Map<String, dynamic> json) {
    return NutritionTargetsModel(
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
      calorieTarget: (json['calorie_target'] as num).toDouble(),
      proteinTarget: (json['protein_target'] as num).toDouble(),
      carbohydratesTarget: (json['carbohydrates_target'] as num).toDouble(),
      fatTarget: (json['fat_target'] as num).toDouble(),
      fiberTarget: (json['fiber_target'] as num).toDouble(),
      waterTargetMl: (json['water_target_ml'] as num).toDouble(),
    );
  }
}

class UserProfileResponseModel {
  final UserProfileModel profile;
  final GoalModel goal;
  final double bmr;
  final double tdee;

  UserProfileResponseModel({
    required this.profile,
    required this.goal,
    required this.bmr,
    required this.tdee,
  });

  factory UserProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseModel(
      profile: UserProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      goal: GoalModel.fromJson(json['goal'] as Map<String, dynamic>),
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
    );
  }
}
