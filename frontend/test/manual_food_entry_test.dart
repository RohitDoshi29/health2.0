import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/analysis_model.dart';
import 'package:heathify_app/data/models/favorite_model.dart';
import 'package:heathify_app/data/models/meal_model.dart';
import 'package:heathify_app/data/models/nutrition_model.dart';
import 'package:heathify_app/data/repositories/favorite_repository.dart';
import 'package:heathify_app/data/repositories/meal_repository.dart';
import 'package:heathify_app/ui/features/manual/manual_food_entry_view.dart';

class MockMealRepository extends MealRepository {
  bool saveMealCalled = false;
  String? lastMealType;
  List<MealItemAnalysisModel>? lastItems;

  @override
  Future<MealModel> saveMeal({
    required String mealType,
    required List<MealItemAnalysisModel> items,
    String? imageUrl,
  }) async {
    saveMealCalled = true;
    lastMealType = mealType;
    lastItems = items;
    return MealModel(
      id: 'meal_123',
      userId: 'user_1',
      mealType: mealType,
      totalCalories: items.fold(0.0, (s, i) => s + i.estimatedCalories),
      totalProtein: items.fold(0.0, (s, i) => s + i.protein),
      totalCarbohydrates: items.fold(0.0, (s, i) => s + i.carbohydrates),
      totalFat: items.fold(0.0, (s, i) => s + i.fat),
      totalFiber: items.fold(0.0, (s, i) => s + i.fiber),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: items
          .map((i) => MealItemModel(
                id: 'item_1',
                foodName: i.name,
                quantity: i.quantity,
                unit: i.unit,
                calories: i.estimatedCalories,
                protein: i.protein,
                carbohydrates: i.carbohydrates,
                fat: i.fat,
                fiber: i.fiber,
                createdAt: DateTime.now(),
              ))
          .toList(),
    );
  }

  @override
  Future<List<FoodItemModel>> searchFoods(String query) async {
    if (query.toLowerCase().contains('paneer')) {
      return [
        const FoodItemModel(
          id: 'food_1',
          name: 'Paneer Butter Masala',
          canonicalName: 'paneer_butter_masala',
          servingSize: 150.0,
          servingUnit: 'g',
          calories: 320.0,
          protein: 14.0,
          carbohydrates: 12.0,
          fat: 24.0,
          fiber: 2.0,
        ),
      ];
    }
    return [];
  }
}

class MockFavoriteRepository extends FavoriteRepository {
  bool createFavoriteCalled = false;
  String? lastTemplateName;

  @override
  Future<FavoriteModel> createFavorite({
    required String name,
    required String mealType,
    required List<MealItemAnalysisModel> items,
  }) async {
    createFavoriteCalled = true;
    lastTemplateName = name;
    return FavoriteModel(
      id: 'fav_1',
      userId: 'user_1',
      name: name,
      mealType: mealType,
      items: items
          .map((i) => FavoriteItemModel(
                foodName: i.name,
                quantity: i.quantity,
                unit: i.unit,
                calories: i.estimatedCalories,
                protein: i.protein,
                carbohydrates: i.carbohydrates,
                fat: i.fat,
                fiber: i.fiber,
              ))
          .toList(),
      totalCalories: 300,
      totalProtein: 20,
      totalCarbohydrates: 30,
      totalFat: 10,
      totalFiber: 2,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('ManualFoodEntryView Widget Tests', () {
    testWidgets('renders all manual input fields and summary correctly', (tester) async {
      final mockMealRepo = MockMealRepository();
      final mockFavRepo = MockFavoriteRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ManualFoodEntryView(
            mealRepository: mockMealRepo,
            favoriteRepository: mockFavRepo,
          ),
        ),
      );

      expect(find.text('Manual Food Entry'), findsOneWidget);
      expect(find.text('Meal Type'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Snack'), findsOneWidget);
      expect(find.text('Food Details & Nutritional Values'), findsOneWidget);
      expect(find.text('Food Name *'), findsOneWidget);
      expect(find.text('Serving Quantity *'), findsOneWidget);
      expect(find.text('Calories (kcal) *'), findsOneWidget);
      expect(find.text('Log Meal'), findsOneWidget);
    });

    testWidgets('user enters custom values and logs meal successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockMealRepo = MockMealRepository();
      final mockFavRepo = MockFavoriteRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ManualFoodEntryView(
            mealRepository: mockMealRepo,
            favoriteRepository: mockFavRepo,
          ),
        ),
      );

      // Enter food name
      final nameField = find.widgetWithText(TextField, 'Food Name *');
      await tester.enterText(nameField, 'Custom Protein Shake');

      // Enter calories
      final calField = find.widgetWithText(TextField, 'Calories (kcal) *');
      await tester.enterText(calField, '280');

      // Enter protein
      final proteinField = find.widgetWithText(TextField, 'Protein (g)');
      await tester.enterText(proteinField, '32.5');

      // Enter carbs
      final carbsField = find.widgetWithText(TextField, 'Carbs (g)');
      await tester.enterText(carbsField, '15.0');

      // Enter fat
      final fatField = find.widgetWithText(TextField, 'Fat (g)');
      await tester.enterText(fatField, '4.0');

      await tester.pumpAndSettle();

      // Verify summary shows 280 kcal
      expect(find.text('280 kcal'), findsOneWidget);
      expect(find.text('32.5g'), findsOneWidget);

      // Tap Log Meal
      await tester.ensureVisible(find.text('Log Meal'));
      await tester.tap(find.text('Log Meal'));
      await tester.pumpAndSettle();

      expect(mockMealRepo.saveMealCalled, isTrue);
      expect(mockMealRepo.lastItems?.length, 1);
      expect(mockMealRepo.lastItems?.first.name, 'Custom Protein Shake');
      expect(mockMealRepo.lastItems?.first.estimatedCalories, 280.0);
      expect(mockMealRepo.lastItems?.first.protein, 32.5);
    });

    testWidgets('user can add multiple items to a meal plate', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockMealRepo = MockMealRepository();
      final mockFavRepo = MockFavoriteRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ManualFoodEntryView(
            mealRepository: mockMealRepo,
            favoriteRepository: mockFavRepo,
          ),
        ),
      );

      // Item 1: Roti
      await tester.enterText(find.widgetWithText(TextField, 'Food Name *'), 'Whole Wheat Roti');
      await tester.enterText(find.widgetWithText(TextField, 'Calories (kcal) *'), '120');
      await tester.enterText(find.widgetWithText(TextField, 'Protein (g)'), '3.5');
      await tester.pumpAndSettle();

      // Tap Add Another Item
      await tester.ensureVisible(find.text('+ Add Another Item to Meal'));
      await tester.tap(find.text('+ Add Another Item to Meal'));
      await tester.pumpAndSettle();

      expect(find.text('Items in this Meal (1)'), findsOneWidget);
      expect(find.text('Whole Wheat Roti'), findsOneWidget);

      // Item 2: Dal
      await tester.enterText(find.widgetWithText(TextField, 'Food Name *'), 'Moong Dal');
      await tester.enterText(find.widgetWithText(TextField, 'Calories (kcal) *'), '180');
      await tester.enterText(find.widgetWithText(TextField, 'Protein (g)'), '10.0');
      await tester.pumpAndSettle();

      // Total should be 120 + 180 = 300 kcal
      expect(find.text('300 kcal'), findsOneWidget);

      // Tap Log Meal
      await tester.ensureVisible(find.text('Log Meal'));
      await tester.tap(find.text('Log Meal'));
      await tester.pumpAndSettle();

      expect(mockMealRepo.saveMealCalled, isTrue);
      expect(mockMealRepo.lastItems?.length, 2);
    });
  });
}
