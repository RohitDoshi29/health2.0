class DailyAveragesModel {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double waterMl;

  DailyAveragesModel({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.waterMl,
  });

  factory DailyAveragesModel.fromJson(Map<String, dynamic> json) {
    return DailyAveragesModel(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      waterMl: (json['water_ml'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'water_ml': waterMl,
    };
  }
}

class DaySummaryModel {
  final String date;
  final String dayName;
  final int score;
  final double calories;

  DaySummaryModel({
    required this.date,
    required this.dayName,
    required this.score,
    required this.calories,
  });

  factory DaySummaryModel.fromJson(Map<String, dynamic> json) {
    return DaySummaryModel(
      date: json['date'] as String,
      dayName: json['day_name'] as String,
      score: json['score'] as int? ?? 0,
      calories: (json['calories'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_name': dayName,
      'score': score,
      'calories': calories,
    };
  }
}

class NutrientHitsModel {
  final int calories;
  final int protein;
  final int carbohydrates;
  final int fat;
  final int fiber;
  final int water;

  NutrientHitsModel({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.water,
  });

  factory NutrientHitsModel.fromJson(Map<String, dynamic> json) {
    return NutrientHitsModel(
      calories: json['calories'] as int? ?? 0,
      protein: json['protein'] as int? ?? 0,
      carbohydrates: json['carbohydrates'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
      fiber: json['fiber'] as int? ?? 0,
      water: json['water'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'water': water,
    };
  }
}

class WeightChangeModel {
  final double startWeightKg;
  final double endWeightKg;
  final double changeKg;

  WeightChangeModel({
    required this.startWeightKg,
    required this.endWeightKg,
    required this.changeKg,
  });

  factory WeightChangeModel.fromJson(Map<String, dynamic> json) {
    return WeightChangeModel(
      startWeightKg: (json['start_weight_kg'] as num).toDouble(),
      endWeightKg: (json['end_weight_kg'] as num).toDouble(),
      changeKg: (json['change_kg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_weight_kg': startWeightKg,
      'end_weight_kg': endWeightKg,
      'change_kg': changeKg,
    };
  }
}

class PriorWeekComparisonModel {
  final double priorAverageCalories;
  final double priorAverageProtein;
  final double? caloriesPctChange;
  final double? proteinPctChange;

  PriorWeekComparisonModel({
    required this.priorAverageCalories,
    required this.priorAverageProtein,
    this.caloriesPctChange,
    this.proteinPctChange,
  });

  factory PriorWeekComparisonModel.fromJson(Map<String, dynamic> json) {
    return PriorWeekComparisonModel(
      priorAverageCalories: (json['prior_average_calories'] as num).toDouble(),
      priorAverageProtein: (json['prior_average_protein'] as num).toDouble(),
      caloriesPctChange: json['calories_pct_change'] != null
          ? (json['calories_pct_change'] as num).toDouble()
          : null,
      proteinPctChange: json['protein_pct_change'] != null
          ? (json['protein_pct_change'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prior_average_calories': priorAverageCalories,
      'prior_average_protein': priorAverageProtein,
      'calories_pct_change': caloriesPctChange,
      'protein_pct_change': proteinPctChange,
    };
  }
}

class DailyBarPointModel {
  final String date;
  final String dayName;
  final double calories;
  final double calorieTarget;
  final int score;
  final bool targetHit;

  DailyBarPointModel({
    required this.date,
    required this.dayName,
    required this.calories,
    required this.calorieTarget,
    required this.score,
    required this.targetHit,
  });

  factory DailyBarPointModel.fromJson(Map<String, dynamic> json) {
    return DailyBarPointModel(
      date: json['date'] as String,
      dayName: json['day_name'] as String,
      calories: (json['calories'] as num).toDouble(),
      calorieTarget: (json['calorie_target'] as num).toDouble(),
      score: json['score'] as int? ?? 0,
      targetHit: json['target_hit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_name': dayName,
      'calories': calories,
      'calorie_target': calorieTarget,
      'score': score,
      'target_hit': targetHit,
    };
  }
}

class WeeklyReportResponseModel {
  final int weekOffset;
  final String startDate;
  final String endDate;
  final DailyAveragesModel dailyAverages;
  final DaySummaryModel bestDay;
  final DaySummaryModel worstDay;
  final NutrientHitsModel nutrientHits;
  final WeightChangeModel? weightChange;
  final PriorWeekComparisonModel priorWeekComparison;
  final List<DailyBarPointModel> dailyPoints;

  WeeklyReportResponseModel({
    required this.weekOffset,
    required this.startDate,
    required this.endDate,
    required this.dailyAverages,
    required this.bestDay,
    required this.worstDay,
    required this.nutrientHits,
    this.weightChange,
    required this.priorWeekComparison,
    required this.dailyPoints,
  });

  factory WeeklyReportResponseModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReportResponseModel(
      weekOffset: json['week_offset'] as int? ?? 0,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      dailyAverages: DailyAveragesModel.fromJson(
          json['daily_averages'] as Map<String, dynamic>),
      bestDay:
          DaySummaryModel.fromJson(json['best_day'] as Map<String, dynamic>),
      worstDay:
          DaySummaryModel.fromJson(json['worst_day'] as Map<String, dynamic>),
      nutrientHits: NutrientHitsModel.fromJson(
          json['nutrient_hits'] as Map<String, dynamic>),
      weightChange: json['weight_change'] != null
          ? WeightChangeModel.fromJson(
              json['weight_change'] as Map<String, dynamic>)
          : null,
      priorWeekComparison: PriorWeekComparisonModel.fromJson(
          json['prior_week_comparison'] as Map<String, dynamic>),
      dailyPoints: (json['daily_points'] as List<dynamic>? ?? [])
          .map((e) => DailyBarPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
