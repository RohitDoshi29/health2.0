import 'goal_model.dart';

class DailyTrendPointModel {
  final String date;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final int mealsCount;
  final double calorieTarget;

  const DailyTrendPointModel({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.mealsCount,
    required this.calorieTarget,
  });

  factory DailyTrendPointModel.fromJson(Map<String, dynamic> json) {
    return DailyTrendPointModel(
      date: json['date'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      mealsCount: json['meals_count'] as int,
      calorieTarget: (json['calorie_target'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'meals_count': mealsCount,
      'calorie_target': calorieTarget,
    };
  }
}

class TrendsAnalyticsModel {
  final String period;
  final int daysCount;
  final String startDate;
  final String endDate;
  final double averageCalories;
  final double averageProtein;
  final double averageCarbohydrates;
  final double averageFat;
  final double averageFiber;
  final GoalModel goal;
  final List<DailyTrendPointModel> dataPoints;

  const TrendsAnalyticsModel({
    required this.period,
    required this.daysCount,
    required this.startDate,
    required this.endDate,
    required this.averageCalories,
    required this.averageProtein,
    required this.averageCarbohydrates,
    required this.averageFat,
    required this.averageFiber,
    required this.goal,
    required this.dataPoints,
  });

  factory TrendsAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return TrendsAnalyticsModel(
      period: json['period'] as String,
      daysCount: json['days_count'] as int,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      averageCalories: (json['average_calories'] as num).toDouble(),
      averageProtein: (json['average_protein'] as num).toDouble(),
      averageCarbohydrates: (json['average_carbohydrates'] as num).toDouble(),
      averageFat: (json['average_fat'] as num).toDouble(),
      averageFiber: (json['average_fiber'] as num).toDouble(),
      goal: GoalModel.fromJson(json['goal'] as Map<String, dynamic>),
      dataPoints: (json['data_points'] as List<dynamic>)
          .map((e) => DailyTrendPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

