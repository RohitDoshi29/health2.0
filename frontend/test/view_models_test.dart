import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/analysis_model.dart';
import 'package:heathify_app/data/models/meal_model.dart';
import 'package:heathify_app/ui/features/home/home_view_model.dart';
import 'package:heathify_app/ui/features/scan/scan_view_model.dart';
import 'package:heathify_app/ui/features/water/water_view_model.dart';

void main() {
  group('ScanViewModel Tests', () {
    test('updateItemQuantity scales macros proportionately', () {
      final vm = ScanViewModel();
      final item = MealItemAnalysisModel(
        name: 'Cooked white rice',
        quantity: 100,
        unit: 'g',
        estimatedCalories: 130,
        protein: 2.7,
        carbohydrates: 28.0,
        fat: 0.3,
        fiber: 0.4,
      );

      vm.editableItems.add(item);
      expect(vm.totalCalories, 130.0);

      // Double the portion to 200g
      vm.updateItemQuantity(0, 200);

      expect(vm.editableItems.first.quantity, 200.0);
      expect(vm.editableItems.first.estimatedCalories, 260.0);
      expect(vm.editableItems.first.protein, 5.4);
      expect(vm.totalCalories, 260.0);
    });

    test('removeItem removes item and recalculates totals', () {
      final vm = ScanViewModel();
      vm.editableItems.addAll([
        MealItemAnalysisModel(
          name: 'Item 1',
          quantity: 100,
          unit: 'g',
          estimatedCalories: 100,
          protein: 10,
          carbohydrates: 10,
          fat: 2,
          fiber: 1,
        ),
        MealItemAnalysisModel(
          name: 'Item 2',
          quantity: 100,
          unit: 'g',
          estimatedCalories: 200,
          protein: 20,
          carbohydrates: 20,
          fat: 4,
          fiber: 2,
        ),
      ]);

      expect(vm.totalCalories, 300.0);
      expect(vm.editableItems.length, 2);

      vm.removeItem(0);
      expect(vm.editableItems.length, 1);
      expect(vm.totalCalories, 200.0);
      expect(vm.editableItems.first.name, 'Item 2');
    });
  });

  group('HomeViewModel Tests', () {
    test('aggregates today macros correctly', () {
      final vm = HomeViewModel();
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      vm.meals.addAll([
        MealModel(
          id: '1',
          userId: 'u1',
          mealType: 'breakfast',
          totalCalories: 400,
          totalProtein: 20,
          totalCarbohydrates: 50,
          totalFat: 10,
          totalFiber: 5,
          createdAt: today,
          updatedAt: today,
          items: [],
        ),
        MealModel(
          id: '2',
          userId: 'u1',
          mealType: 'lunch',
          totalCalories: 600,
          totalProtein: 40,
          totalCarbohydrates: 70,
          totalFat: 15,
          totalFiber: 8,
          createdAt: today,
          updatedAt: today,
          items: [],
        ),
        MealModel(
          id: '3',
          userId: 'u1',
          mealType: 'yesterday dinner',
          totalCalories: 500,
          totalProtein: 30,
          totalCarbohydrates: 50,
          totalFat: 12,
          totalFiber: 6,
          createdAt: yesterday,
          updatedAt: yesterday,
          items: [],
        ),
      ]);

      expect(vm.todayCalories, 1000.0);
      expect(vm.todayProtein, 60.0);
      expect(vm.todayCarbs, 120.0);
      expect(vm.todayFat, 25.0);
      expect(vm.todayFiber, 13.0);
    });
  });

  group('WaterViewModel Tests', () {
    test('initial state has default 2500ml target and 0ml intake', () {
      final vm = WaterViewModel();
      expect(vm.summary.totalMl, 0.0);
      expect(vm.summary.targetMl, 2500.0);
      expect(vm.summary.percentage, 0.0);
      expect(vm.isLoading, isFalse);
    });
  });
}

