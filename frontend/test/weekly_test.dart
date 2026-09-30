import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/weekly_model.dart';
import 'package:heathify_app/ui/features/weekly/weekly_view_model.dart';

void main() {
  group('Weekly Models Tests', () {
    test('WeeklyReportResponseModel deserialization with full data', () {
      final json = {
        'start_date': '2026-03-23',
        'end_date': '2026-03-29',
        'week_offset': 0,
        'daily_averages': {
          'calories': 2100.5,
          'protein': 145.2,
          'carbohydrates': 220.0,
          'fat': 65.8,
          'fiber': 28.4,
          'water_ml': 2400.0,
        },
        'best_day': {
          'date': '2026-03-25',
          'day_name': 'Wednesday',
          'score': 95,
          'calories': 2005.0,
        },
        'worst_day': {
          'date': '2026-03-28',
          'day_name': 'Saturday',
          'score': 45,
          'calories': 2650.0,
        },
        'nutrient_hits': {
          'calories': 4,
          'protein': 6,
          'carbohydrates': 5,
          'fat': 6,
          'fiber': 5,
          'water': 7,
        },
        'weight_change': {
          'start_weight_kg': 74.2,
          'end_weight_kg': 73.8,
          'change_kg': -0.4,
        },
        'prior_week_comparison': {
          'prior_average_calories': 2010.0,
          'prior_average_protein': 148.3,
          'calories_pct_change': 4.5,
          'protein_pct_change': -2.1,
        },
        'daily_points': [
          {
            'date': '2026-03-23',
            'day_name': 'Mon',
            'calories': 1980.0,
            'calorie_target': 2000.0,
            'score': 90,
            'target_hit': true,
          },
          {
            'date': '2026-03-24',
            'day_name': 'Tue',
            'calories': 2050.0,
            'calorie_target': 2000.0,
            'score': 85,
            'target_hit': true,
          },
        ],
      };

      final report = WeeklyReportResponseModel.fromJson(json);
      expect(report.startDate, '2026-03-23');
      expect(report.endDate, '2026-03-29');
      expect(report.weekOffset, 0);

      expect(report.dailyAverages.calories, 2100.5);
      expect(report.dailyAverages.protein, 145.2);
      expect(report.dailyAverages.fiber, 28.4);
      expect(report.dailyAverages.waterMl, 2400.0);

      expect(report.bestDay.date, '2026-03-25');
      expect(report.bestDay.score, 95);
      expect(report.worstDay.date, '2026-03-28');
      expect(report.worstDay.score, 45);

      expect(report.nutrientHits.protein, 6);
      expect(report.nutrientHits.water, 7);

      expect(report.weightChange?.startWeightKg, 74.2);
      expect(report.weightChange?.endWeightKg, 73.8);
      expect(report.weightChange?.changeKg, -0.4);

      expect(report.priorWeekComparison.caloriesPctChange, 4.5);
      expect(report.priorWeekComparison.proteinPctChange, -2.1);
      expect(report.priorWeekComparison.priorAverageCalories, 2010.0);

      expect(report.dailyPoints.length, 2);
      expect(report.dailyPoints[0].dayName, 'Mon');
      expect(report.dailyPoints[0].targetHit, isTrue);
    });

    test('WeeklyReport handles null prior week and empty weight logs', () {
      final json = {
        'start_date': '2026-03-23',
        'end_date': '2026-03-29',
        'week_offset': -2,
        'daily_averages': {
          'calories': 0.0,
          'protein': 0.0,
          'carbohydrates': 0.0,
          'fat': 0.0,
          'fiber': 0.0,
          'water_ml': 0.0,
        },
        'best_day': {
          'date': '2026-03-23',
          'day_name': 'Mon',
          'score': 0,
          'calories': 0.0,
        },
        'worst_day': {
          'date': '2026-03-23',
          'day_name': 'Mon',
          'score': 0,
          'calories': 0.0,
        },
        'nutrient_hits': {
          'calories': 0,
          'protein': 0,
          'carbohydrates': 0,
          'fat': 0,
          'fiber': 0,
          'water': 0,
        },
        'weight_change': null,
        'prior_week_comparison': {
          'prior_average_calories': 0.0,
          'prior_average_protein': 0.0,
          'calories_pct_change': null,
          'protein_pct_change': null,
        },
        'daily_points': [],
      };

      final report = WeeklyReportResponseModel.fromJson(json);
      expect(report.weightChange, isNull);
      expect(report.priorWeekComparison.caloriesPctChange, isNull);
      expect(report.dailyPoints, isEmpty);
    });
  });

  group('WeeklyViewModel State Tests', () {
    test('Initial state and week navigation logic', () {
      final vm = WeeklyViewModel();
      expect(vm.weekOffset, 0);
      expect(vm.isLoading, isFalse);
      expect(vm.report, isNull);
      expect(vm.canGoNext, isFalse); // Cannot go to future weeks

      // Test week offset navigation logic
      vm.previousWeek(); // triggers offset -1
      expect(vm.weekOffset, -1);
      expect(vm.canGoNext, isTrue);

      vm.nextWeek(); // triggers offset 0
      expect(vm.weekOffset, 0);
      expect(vm.canGoNext, isFalse);
    });
  });
}
