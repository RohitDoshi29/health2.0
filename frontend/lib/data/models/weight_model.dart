class WeightLogModel {
  final String id;
  final String userId;
  final double weightKg;
  final DateTime loggedAt;
  final String? note;
  final DateTime createdAt;

  WeightLogModel({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedAt,
    this.note,
    required this.createdAt,
  });

  factory WeightLogModel.fromJson(Map<String, dynamic> json) {
    return WeightLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      loggedAt: DateTime.parse(json['logged_at'] as String),
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weight_kg': weightKg,
      'logged_at': loggedAt.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class WeightHistoryPointModel {
  final String date;
  final double weightKg;
  final double? caloriesConsumed;

  WeightHistoryPointModel({
    required this.date,
    required this.weightKg,
    this.caloriesConsumed,
  });

  factory WeightHistoryPointModel.fromJson(Map<String, dynamic> json) {
    return WeightHistoryPointModel(
      date: json['date'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      caloriesConsumed: json['calories_consumed'] != null
          ? (json['calories_consumed'] as num).toDouble()
          : null,
    );
  }
}

class WeightHistoryResponseModel {
  final List<WeightHistoryPointModel> points;
  final double? currentWeight;
  final double? startWeight;
  final double? changeTotalKg;
  final double? change7dKg;
  final int days;

  WeightHistoryResponseModel({
    required this.points,
    this.currentWeight,
    this.startWeight,
    this.changeTotalKg,
    this.change7dKg,
    required this.days,
  });

  factory WeightHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return WeightHistoryResponseModel(
      points: (json['points'] as List<dynamic>)
          .map((e) => WeightHistoryPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentWeight: json['current_weight'] != null
          ? (json['current_weight'] as num).toDouble()
          : null,
      startWeight: json['start_weight'] != null
          ? (json['start_weight'] as num).toDouble()
          : null,
      changeTotalKg: json['change_total_kg'] != null
          ? (json['change_total_kg'] as num).toDouble()
          : null,
      change7dKg: json['change_7d_kg'] != null
          ? (json['change_7d_kg'] as num).toDouble()
          : null,
      days: json['days'] as int? ?? 30,
    );
  }
}
