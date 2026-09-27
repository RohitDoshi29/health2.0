import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/goal_model.dart';
import 'package:heathify_app/ui/core/widgets/macro_progress_ring.dart';

void main() {
  group('Goal Models Serialization Tests', () {
    test('GoalModel deserialization and serialization', () {
      final json = {
        'id': 'goal-123',
        'user_id': 'user-456',
        'calorie_target': 2200.0,
        'protein_target': 140.0,
        'carbohydrates_target': 260.0,
        'fat_target': 70.0,
        'fiber_target': 35.0,
        'created_at': '2026-09-22T12:00:00.000Z',
        'updated_at': '2026-09-22T12:00:00.000Z',
      };

      final goal = GoalModel.fromJson(json);
      expect(goal.id, 'goal-123');
      expect(goal.calorieTarget, 2200.0);
      expect(goal.proteinTarget, 140.0);
      expect(goal.carbohydratesTarget, 260.0);
      expect(goal.fatTarget, 70.0);
      expect(goal.fiberTarget, 35.0);

      final outJson = goal.toJson();
      expect(outJson['calorie_target'], 2200.0);
      expect(outJson['protein_target'], 140.0);
    });

    test('DailyAnalyticsModel deserialization and ratio calculations', () {
      final json = {
        'date': '2026-09-22',
        'goal': {
          'id': 'goal-123',
          'user_id': 'user-456',
          'calorie_target': 2000.0,
          'protein_target': 100.0,
          'carbohydrates_target': 200.0,
          'fat_target': 50.0,
          'fiber_target': 25.0,
        },
        'consumed_calories': 1000.0,
        'consumed_protein': 50.0,
        'consumed_carbohydrates': 100.0,
        'consumed_fat': 25.0,
        'consumed_fiber': 12.5,
        'calorie_progress': 0.5,
        'protein_progress': 0.5,
        'carbohydrates_progress': 0.5,
        'fat_progress': 0.5,
        'fiber_progress': 0.5,
        'meals_count': 2,
      };

      final analytics = DailyAnalyticsModel.fromJson(json);
      expect(analytics.date, '2026-09-22');
      expect(analytics.consumedCalories, 1000.0);
      expect(analytics.calorieProgress, 0.5);
      expect(analytics.mealsCount, 2);
      expect(analytics.goal.calorieTarget, 2000.0);
    });
  });

  group('MacroProgressRing Widget Tests', () {
    testWidgets('renders daily target, remaining calories, and macro progress bars', (tester) async {
      final analytics = DailyAnalyticsModel(
        date: '2026-09-22',
        goal: GoalModel(
          id: 'goal-1',
          userId: 'user-1',
          calorieTarget: 2000,
          proteinTarget: 120,
          carbohydratesTarget: 250,
          fatTarget: 65,
          fiberTarget: 30,
        ),
        consumedCalories: 1500,
        consumedProtein: 90,
        consumedCarbohydrates: 180,
        consumedFat: 45,
        consumedFiber: 20,
        calorieProgress: 0.75,
        proteinProgress: 0.75,
        carbohydratesProgress: 0.72,
        fatProgress: 0.69,
        fiberProgress: 0.67,
        mealsCount: 3,
      );

      bool editGoalsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MacroProgressRing(
              analytics: analytics,
              onEditGoals: () {
                editGoalsTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Daily Target & Progress'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('1500 / 2000 kcal'), findsOneWidget);
      expect(find.text('500 kcal remaining'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Fiber'), findsOneWidget);

      await tester.tap(find.text('Edit Goals'));
      expect(editGoalsTapped, isTrue);
    });
  });
}

