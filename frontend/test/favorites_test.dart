import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/favorite_model.dart';
import 'package:heathify_app/data/models/meal_model.dart';
import 'package:heathify_app/data/repositories/favorite_repository.dart';
import 'package:heathify_app/ui/core/widgets/favorites_sheet.dart';

class MockFavoriteRepository extends FavoriteRepository {
  List<FavoriteModel> fakeFavorites = [];
  bool quickLogCalled = false;

  @override
  Future<List<FavoriteModel>> getFavorites() async {
    return fakeFavorites;
  }

  @override
  Future<MealModel> quickLogFavorite(String id) async {
    quickLogCalled = true;
    return MealModel(
      id: 'meal-123',
      userId: 'user-1',
      mealType: 'breakfast',
      totalCalories: 225.0,
      totalProtein: 25.0,
      totalCarbohydrates: 29.0,
      totalFat: 2.0,
      totalFiber: 3.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
    );
  }

  @override
  Future<void> deleteFavorite(String id) async {
    fakeFavorites.removeWhere((f) => f.id == id);
  }
}

void main() {
  group('FavoriteModel Tests', () {
    final sampleJson = {
      'id': 'fav-1',
      'user_id': 'user-1',
      'name': 'Morning Oatmeal & Berries',
      'meal_type': 'breakfast',
      'total_calories': 280.0,
      'total_protein': 12.0,
      'total_carbohydrates': 52.0,
      'total_fat': 4.0,
      'total_fiber': 8.0,
      'created_at': '2026-09-22T08:00:00.000Z',
      'items_json': [
        {
          'food_id': 'food-1',
          'food_name': 'Rolled Oats',
          'quantity': 50.0,
          'unit': 'g',
          'calories': 190.0,
          'protein': 7.0,
          'carbohydrates': 32.0,
          'fat': 3.5,
          'fiber': 5.0,
        },
        {
          'food_id': 'food-2',
          'food_name': 'Blueberries',
          'quantity': 100.0,
          'unit': 'g',
          'calories': 90.0,
          'protein': 1.0,
          'carbohydrates': 20.0,
          'fat': 0.5,
          'fiber': 3.0,
        },
      ],
    };

    test('parses FavoriteModel from JSON correctly', () {
      final fav = FavoriteModel.fromJson(sampleJson);
      expect(fav.id, 'fav-1');
      expect(fav.name, 'Morning Oatmeal & Berries');
      expect(fav.mealType, 'breakfast');
      expect(fav.totalCalories, 280.0);
      expect(fav.totalProtein, 12.0);
      expect(fav.items.length, 2);
    });

    test('converts items to MealItemAnalysisList', () {
      final fav = FavoriteModel.fromJson(sampleJson);
      final analysisList = fav.toMealItemAnalysisList();

      expect(analysisList.length, 2);
      expect(analysisList[0].name, 'Rolled Oats');
      expect(analysisList[0].estimatedCalories, 190.0);
      expect(analysisList[1].name, 'Blueberries');
      expect(analysisList[1].estimatedCalories, 90.0);
    });
  });

  group('FavoritesSheet Widget Tests', () {
    testWidgets('renders empty state when no favorites exist', (tester) async {
      final mockRepo = MockFavoriteRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoritesSheet(favoriteRepository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Favorite Templates'), findsOneWidget);
      expect(find.text('No Favorites Saved Yet'), findsOneWidget);
    });

    testWidgets('renders favorite templates list and triggers 1-tap quick log', (tester) async {
      final mockRepo = MockFavoriteRepository()
        ..fakeFavorites = [
          FavoriteModel(
            id: 'fav-1',
            userId: 'user-1',
            name: 'Protein Shake',
            mealType: 'breakfast',
            totalCalories: 225.0,
            totalProtein: 25.0,
            totalCarbohydrates: 29.0,
            totalFat: 2.0,
            totalFiber: 3.0,
            createdAt: DateTime.now(),
            items: const [
              FavoriteItemModel(
                foodName: 'Whey Protein',
                quantity: 30.0,
                unit: 'g',
                calories: 120.0,
                protein: 24.0,
                carbohydrates: 2.0,
                fat: 1.5,
                fiber: 0.0,
              ),
            ],
          ),
        ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoritesSheet(favoriteRepository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Protein Shake'), findsOneWidget);
      expect(find.text('225 kcal'), findsOneWidget);
      expect(find.text('1-Tap Log'), findsOneWidget);

      await tester.tap(find.text('1-Tap Log'));
      await tester.pumpAndSettle();

      expect(mockRepo.quickLogCalled, isTrue);
    });
  });
}
