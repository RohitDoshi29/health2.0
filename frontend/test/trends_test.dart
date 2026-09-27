import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/goal_model.dart';
import 'package:heathify_app/data/models/trend_model.dart';
import 'package:heathify_app/ui/core/widgets/nutrition_trends_chart.dart';

void main() {
  group('Trends Serialization Tests', () {
    test('DailyTrendPointModel serialization and deserialization', () {
      final json = {
        'date': '2026-09-22',
        'calories': 1850.0,
        'protein': 130.0,
        'carbohydrates': 210.0,
        'fat': 55.0,
        'fiber': 28.0,
        'meals_count': 3,
        'calorie_target': 2000.0,
      };

      final point = DailyTrendPointModel.fromJson(json);
      expect(point.date, '2026-09-22');
      expect(point.calories, 1850.0);
      expect(point.protein, 130.0);
      expect(point.mealsCount, 3);
      expect(point.calorieTarget, 2000.0);

      final outJson = point.toJson();
      expect(outJson['date'], '2026-09-22');
      expect(outJson['calories'], 1850.0);
    });

    test('TrendsAnalyticsModel deserialization', () {
      final json = {
        'period': '7d',
        'days_count': 7,
        'start_date': '2026-09-16',
        'end_date': '2026-09-22',
        'average_calories': 1800.0,
        'average_protein': 120.0,
        'average_carbohydrates': 220.0,
        'average_fat': 50.0,
        'average_fiber': 25.0,
        'goal': {
          'id': 'goal-1',
          'user_id': 'user-1',
          'calorie_target': 2000.0,
          'protein_target': 120.0,
          'carbohydrates_target': 250.0,
          'fat_target': 65.0,
          'fiber_target': 30.0,
        },
        'data_points': [
          {
            'date': '2026-09-16',
            'calories': 1900.0,
            'protein': 125.0,
            'carbohydrates': 230.0,
            'fat': 52.0,
            'fiber': 26.0,
            'meals_count': 3,
            'calorie_target': 2000.0,
          }
        ],
      };

      final trends = TrendsAnalyticsModel.fromJson(json);
      expect(trends.period, '7d');
      expect(trends.daysCount, 7);
      expect(trends.averageCalories, 1800.0);
      expect(trends.goal.calorieTarget, 2000.0);
      expect(trends.dataPoints.length, 1);
      expect(trends.dataPoints.first.calories, 1900.0);
    });
  });

  group('NutritionTrendsChart Widget Tests', () {
    testWidgets('renders averages, period toggles, and bars', (tester) async {
      final goal = GoalModel(
        id: 'goal-1',
        userId: 'user-1',
        calorieTarget: 2000,
        proteinTarget: 120,
        carbohydratesTarget: 250,
        fatTarget: 65,
        fiberTarget: 30,
      );

      final trends = TrendsAnalyticsModel(
        period: '7d',
        daysCount: 7,
        startDate: '2026-09-16',
        endDate: '2026-09-22',
        averageCalories: 1750,
        averageProtein: 110,
        averageCarbohydrates: 215,
        averageFat: 50,
        averageFiber: 25,
        goal: goal,
        dataPoints: [
          DailyTrendPointModel(
            date: '2026-09-21',
            calories: 1600,
            protein: 100,
            carbohydrates: 200,
            fat: 45,
            fiber: 20,
            mealsCount: 2,
            calorieTarget: 2000,
          ),
          DailyTrendPointModel(
            date: '2026-09-22',
            calories: 1900,
            protein: 120,
            carbohydrates: 230,
            fat: 55,
            fiber: 30,
            mealsCount: 3,
            calorieTarget: 2000,
          ),
        ],
      );

      int? requestedPeriod;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NutritionTrendsChart(
                trends: trends,
                selectedDays: 7,
                onPeriodChanged: (days) {
                  requestedPeriod = days;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nutrition Trends'), findsOneWidget);
      expect(find.text('Avg Cal'), findsOneWidget);
      expect(find.text('1750 kcal'), findsOneWidget);
      expect(find.text('Target: 2000 kcal'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);

      await tester.tap(find.text('30 Days'));
      expect(requestedPeriod, 30);
    });
  });
}
