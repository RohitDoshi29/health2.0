import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/meal_model.dart';
import 'package:heathify_app/data/models/recent_food_model.dart';
import 'package:heathify_app/data/repositories/meal_repository.dart';
import 'package:heathify_app/ui/features/home/home_view_model.dart';
import 'package:heathify_app/ui/features/scan/scan_view_model.dart';

class MockMealRepository extends MealRepository {
  final List<RecentFoodModel> mockRecents;
  MealModel? lastReloggedMeal;

  MockMealRepository({this.mockRecents = const []});

  @override
  Future<List<RecentFoodModel>> getRecentFoods({int limit = 20}) async {
    return mockRecents.take(limit).toList();
  }

  @override
  Future<MealModel> relogMeal(String mealId, {int? tzOffset}) async {
    final relogged = MealModel(
      id: 'relogged-meal-999',
      userId: 'test-user',
      mealType: 'lunch',
      totalCalories: 350.0,
      totalProtein: 25.0,
      totalCarbohydrates: 40.0,
      totalFat: 10.0,
      totalFiber: 5.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [
        MealItemModel(
          id: 'item-1',
          foodName: 'Grilled Chicken Breast',
          quantity: 150.0,
          unit: 'g',
          calories: 250.0,
          protein: 25.0,
          carbohydrates: 0.0,
          fat: 5.0,
          fiber: 0.0,
          createdAt: DateTime.now(),
        ),
      ],
    );
    lastReloggedMeal = relogged;
    return relogged;
  }
}

void main() {
  group('RecentFoodModel Tests', () {
    test('JSON deserialization and serialization roundtrip', () {
      final json = {
        'food_id': 'food-uuid-1',
        'food_name': 'Avocado Toast',
        'quantity': 120.0,
        'unit': 'g',
        'calories': 240.0,
        'protein': 4.5,
        'carbohydrates': 22.0,
        'fat': 16.0,
        'fiber': 7.0,
        'last_logged_at': '2026-03-30T09:30:00.000Z',
      };

      final model = RecentFoodModel.fromJson(json);
      expect(model.foodId, 'food-uuid-1');
      expect(model.foodName, 'Avocado Toast');
      expect(model.quantity, 120.0);
      expect(model.unit, 'g');
      expect(model.calories, 240.0);
      expect(model.protein, 4.5);
      expect(model.carbohydrates, 22.0);
      expect(model.fat, 16.0);
      expect(model.fiber, 7.0);
      expect(model.lastLoggedAt, DateTime.parse('2026-03-30T09:30:00.000Z'));

      final out = model.toJson();
      expect(out['food_name'], 'Avocado Toast');
      expect(out['calories'], 240.0);
      expect(out['unit'], 'g');
    });
  });

  group('ScanViewModel Recent Foods Integration Tests', () {
    test('addRecentFood appends item and updates total nutrition', () {
      final scanVm = ScanViewModel();
      expect(scanVm.editableItems, isEmpty);
      expect(scanVm.totalCalories, 0.0);

      final recentItem = RecentFoodModel(
        foodName: 'Greek Yogurt',
        quantity: 170.0,
        unit: 'g',
        calories: 130.0,
        protein: 17.0,
        carbohydrates: 6.0,
        fat: 4.0,
        fiber: 0.0,
        lastLoggedAt: DateTime.parse('2026-03-30T08:00:00Z'),
      );

      scanVm.addRecentFood(recentItem);

      expect(scanVm.editableItems.length, 1);
      final item = scanVm.editableItems.first;
      expect(item.name, 'Greek Yogurt');
      expect(item.quantity, 170.0);
      expect(item.estimatedCalories, 130.0);
      expect(item.protein, 17.0);

      expect(scanVm.totalCalories, 130.0);
      expect(scanVm.totalProtein, 17.0);
    });
  });

  group('HomeViewModel Relog Integration Tests', () {
    test('relogMeal prepends newly relogged meal to meal list', () async {
      final mockRepo = MockMealRepository();
      final homeVm = HomeViewModel(mealRepository: mockRepo);

      expect(homeVm.meals, isEmpty);

      final relogged = await homeVm.relogMeal('original-meal-123');

      expect(relogged.id, 'relogged-meal-999');
      expect(homeVm.meals.length, 1);
      expect(homeVm.meals.first.id, 'relogged-meal-999');
      expect(homeVm.meals.first.totalCalories, 350.0);
      expect(homeVm.meals.first.items.first.foodName, 'Grilled Chicken Breast');
    });
  });
}
