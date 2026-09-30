class ScoreBreakdownItemModel {
  final double points;
  final double maxPoints;
  final bool achieved;
  final double value;
  final double target;
  final String description;

  ScoreBreakdownItemModel({
    required this.points,
    required this.maxPoints,
    required this.achieved,
    required this.value,
    required this.target,
    required this.description,
  });

  factory ScoreBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdownItemModel(
      points: (json['points'] as num).toDouble(),
      maxPoints: (json['max_points'] as num).toDouble(),
      achieved: json['achieved'] as bool? ?? false,
      value: (json['value'] as num).toDouble(),
      target: (json['target'] as num).toDouble(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'max_points': maxPoints,
      'achieved': achieved,
      'value': value,
      'target': target,
      'description': description,
    };
  }
}

class DailyScoreBreakdownModel {
  final ScoreBreakdownItemModel calories;
  final ScoreBreakdownItemModel protein;
  final ScoreBreakdownItemModel fiber;
  final ScoreBreakdownItemModel water;

  DailyScoreBreakdownModel({
    required this.calories,
    required this.protein,
    required this.fiber,
    required this.water,
  });

  factory DailyScoreBreakdownModel.fromJson(Map<String, dynamic> json) {
    return DailyScoreBreakdownModel(
      calories: ScoreBreakdownItemModel.fromJson(json['calories'] as Map<String, dynamic>),
      protein: ScoreBreakdownItemModel.fromJson(json['protein'] as Map<String, dynamic>),
      fiber: ScoreBreakdownItemModel.fromJson(json['fiber'] as Map<String, dynamic>),
      water: ScoreBreakdownItemModel.fromJson(json['water'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories.toJson(),
      'protein': protein.toJson(),
      'fiber': fiber.toJson(),
      'water': water.toJson(),
    };
  }
}

class DailyScoreModel {
  final String date;
  final int score;
  final DailyScoreBreakdownModel breakdown;

  DailyScoreModel({
    required this.date,
    required this.score,
    required this.breakdown,
  });

  factory DailyScoreModel.fromJson(Map<String, dynamic> json) {
    return DailyScoreModel(
      date: json['date'] as String,
      score: json['score'] as int? ?? 0,
      breakdown: DailyScoreBreakdownModel.fromJson(json['breakdown'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'score': score,
      'breakdown': breakdown.toJson(),
    };
  }
}

class EarnedBadgeIdModel {
  final String id;
  final String earnedAt;

  EarnedBadgeIdModel({required this.id, required this.earnedAt});

  factory EarnedBadgeIdModel.fromJson(Map<String, dynamic> json) {
    return EarnedBadgeIdModel(
      id: json['id'] as String,
      earnedAt: json['earned_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'earned_at': earnedAt,
    };
  }
}

class BadgeItemModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool unlocked;
  final String? earnedAt;

  BadgeItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.earnedAt,
  });

  factory BadgeItemModel.fromJson(Map<String, dynamic> json) {
    return BadgeItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
      earnedAt: json['earned_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'unlocked': unlocked,
      'earned_at': earnedAt,
    };
  }
}

class StreaksResponseModel {
  final int currentStreak;
  final int longestStreak;
  final DailyScoreModel todayScore;
  final bool streakActiveToday;
  final List<EarnedBadgeIdModel> earnedBadges;
  final List<BadgeItemModel> badges;

  StreaksResponseModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.todayScore,
    required this.streakActiveToday,
    required this.earnedBadges,
    required this.badges,
  });

  factory StreaksResponseModel.fromJson(Map<String, dynamic> json) {
    return StreaksResponseModel(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      todayScore: DailyScoreModel.fromJson(json['today_score'] as Map<String, dynamic>),
      streakActiveToday: json['streak_active_today'] as bool? ?? false,
      earnedBadges: (json['earned_badges'] as List<dynamic>? ?? [])
          .map((e) => EarnedBadgeIdModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => BadgeItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
