class WaterLogModel {
  final String id;
  final String userId;
  final double amountMl;
  final DateTime loggedAt;

  WaterLogModel({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.loggedAt,
  });

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    return WaterLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amountMl: (json['amount_ml'] as num).toDouble(),
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount_ml': amountMl,
      'logged_at': loggedAt.toIso8601String(),
    };
  }
}

class DailyWaterSummaryModel {
  final String date;
  final double totalMl;
  final double targetMl;
  final double percentage;
  final int logsCount;
  final List<WaterLogModel> logs;

  DailyWaterSummaryModel({
    required this.date,
    required this.totalMl,
    required this.targetMl,
    required this.percentage,
    required this.logsCount,
    required this.logs,
  });

  factory DailyWaterSummaryModel.fromJson(Map<String, dynamic> json) {
    return DailyWaterSummaryModel(
      date: json['date'] as String,
      totalMl: (json['total_ml'] as num).toDouble(),
      targetMl: (json['target_ml'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      logsCount: json['logs_count'] as int? ?? (json['logs'] as List<dynamic>?)?.length ?? 0,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => WaterLogModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory DailyWaterSummaryModel.initial() {
    return DailyWaterSummaryModel(
      date: DateTime.now().toIso8601String().split('T').first,
      totalMl: 0.0,
      targetMl: 2500.0,
      percentage: 0.0,
      logsCount: 0,
      logs: [],
    );
  }
}

class WaterHistoryDayModel {
  final String date;
  final double totalMl;
  final double targetMl;
  final double percentage;
  final int logsCount;

  WaterHistoryDayModel({
    required this.date,
    required this.totalMl,
    required this.targetMl,
    required this.percentage,
    required this.logsCount,
  });

  factory WaterHistoryDayModel.fromJson(Map<String, dynamic> json) {
    return WaterHistoryDayModel(
      date: json['date'] as String,
      totalMl: (json['total_ml'] as num).toDouble(),
      targetMl: (json['target_ml'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      logsCount: json['logs_count'] as int? ?? 0,
    );
  }
}

