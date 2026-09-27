import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/analysis_model.dart';
import 'package:heathify_app/data/models/meal_model.dart';
import 'package:heathify_app/data/models/nutrition_model.dart';
import 'package:heathify_app/data/models/user_model.dart';

void main() {
  group('Models Serialization Tests', () {
    test('UserModel and AuthResponseModel deserialization', () {
      final json = {
        'access_token': 'jwt.token.here',
        'token_type': 'bearer',
        'user': {
          'id': '11111111-1111-1111-1111-111111111111',
          'name': 'Test User',
          'email': 'test@example.com',
          'created_at': '2026-09-22T12:00:00.000Z',
        }
      };

      final authResponse = AuthResponseModel.fromJson(json);
      expect(authResponse.accessToken, 'jwt.token.here');
      expect(authResponse.tokenType, 'bearer');
      expect(authResponse.user.name, 'Test User');
      expect(authResponse.user.email, 'test@example.com');
    });

    test('NutritionSummaryModel deserialization', () {
      final json = {
        'estimated_calories': 450.5,
        'protein': 30.2,
        'carbohydrates': 55.0,
        'fat': 12.0,
        'fiber': 6.5,
      };

      final summary = NutritionSummaryModel.fromJson(json);
      expect(summary.estimatedCalories, 450.5);
      expect(summary.protein, 30.2);
      expect(summary.carbohydrates, 55.0);
      expect(summary.fat, 12.0);
      expect(summary.fiber, 6.5);
    });

    test('MealAnalysisResponseModel and MealItemAnalysisModel', () {
      final json = {
        'total': {
          'estimated_calories': 350.0,
          'protein': 25.0,
          'carbohydrates': 40.0,
          'fat': 8.0,
          'fiber': 4.0,
        },
        'items': [
          {
            'name': 'cooked white rice',
            'quantity': 150,
            'unit': 'g',
            'estimated_calories': 195.0,
            'protein': 4.05,
            'carbohydrates': 42.0,
            'fat': 0.45,
            'fiber': 0.6,
            'confidence': 0.95,
            'matched_food_id': 'food-uuid',
          }
        ],
        'disclaimer': 'Estimates only',
      };

      final analysis = MealAnalysisResponseModel.fromJson(json);
      expect(analysis.total.estimatedCalories, 350.0);
      expect(analysis.items.length, 1);
      expect(analysis.items.first.name, 'cooked white rice');
      expect(analysis.items.first.quantity, 150.0);
      expect(analysis.items.first.toMealItemCreateJson()['food_name'], 'cooked white rice');
    });

    test('MealModel and MealItemModel deserialization', () {
      final json = {
        'id': 'meal-uuid',
        'user_id': 'user-uuid',
        'image_url': null,
        'meal_type': 'dinner',
        'total_calories': 500.0,
        'total_protein': 35.0,
        'total_carbohydrates': 60.0,
        'total_fat': 10.0,
        'total_fiber': 5.0,
        'created_at': '2026-09-22T19:00:00.000Z',
        'updated_at': '2026-09-22T19:00:00.000Z',
        'items': [
          {
            'id': 'item-uuid',
            'food_id': null,
            'food_name': 'Chicken',
            'quantity': 100,
            'unit': 'g',
            'calories': 165.0,
            'protein': 31.0,
            'carbohydrates': 0.0,
            'fat': 3.6,
            'fiber': 0.0,
            'confidence': 0.9,
            'created_at': '2026-09-22T19:00:00.000Z',
          }
        ]
      };

      final meal = MealModel.fromJson(json);
      expect(meal.id, 'meal-uuid');
      expect(meal.mealType, 'dinner');
      expect(meal.totalCalories, 500.0);
      expect(meal.items.length, 1);
      expect(meal.items.first.foodName, 'Chicken');
    });
  });
}

