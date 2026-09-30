import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/analysis_model.dart';
import 'package:heathify_app/data/models/portion_model.dart';
import 'package:heathify_app/ui/features/portion/portion_picker_widget.dart';
import 'package:heathify_app/ui/features/scan/scan_view_model.dart';

void main() {
  group('PortionGuideModel Tests', () {
    test('JSON deserialization and serialization roundtrip', () {
      final json = {
        'id': 'p-123',
        'food_canonical_name': 'dal',
        'label': '1 katori dal',
        'grams': 150.0,
        'image_asset': 'assets/portions/katori.png',
      };

      final model = PortionGuideModel.fromJson(json);
      expect(model.id, 'p-123');
      expect(model.foodCanonicalName, 'dal');
      expect(model.label, '1 katori dal');
      expect(model.grams, 150.0);
      expect(model.imageAsset, 'assets/portions/katori.png');

      final serialized = model.toJson();
      expect(serialized['id'], 'p-123');
      expect(serialized['grams'], 150.0);
    });
  });

  group('ScanViewModel updateItemPortion Tests', () {
    test('updates item quantity, unit, calories and applies 1200g cap', () {
      final vm = ScanViewModel();
      vm.editableItems.add(
        MealItemAnalysisModel(
          name: 'Dal Makhani',
          quantity: 100.0,
          unit: 'g',
          estimatedCalories: 150.0,
          protein: 8.0,
          carbohydrates: 20.0,
          fat: 5.0,
          fiber: 4.0,
        ),
      );

      // 1. Normal portion update: 1.5 katori = 225g
      vm.updateItemPortion(
        0,
        newQuantity: 225.0,
        newUnit: 'katori',
        newCalories: 338.0,
        newProtein: 18.0,
        newCarbs: 45.0,
        newFat: 11.2,
        newFiber: 9.0,
      );

      expect(vm.editableItems[0].quantity, 225.0);
      expect(vm.editableItems[0].unit, 'katori');
      expect(vm.editableItems[0].estimatedCalories, 338.0);
      expect(vm.totalCalories, 338.0);

      // 2. Over-cap portion update: 2000g -> must be capped at 1200g
      vm.updateItemPortion(
        0,
        newQuantity: 2000.0,
      );
      expect(vm.editableItems[0].quantity, 1200.0);
    });
  });

  group('PortionPickerWidget Tests', () {
    testWidgets('renders portion chips, stepper, and live calculated values',
        (tester) async {
      PortionGuideModel? lastPortion;
      double? lastMultiplier;
      double? lastGrams;
      double? lastCalories;

      final testPortions = [
        const PortionGuideModel(
          id: 'p1',
          foodCanonicalName: 'dal',
          label: '1 katori',
          grams: 150.0,
        ),
        const PortionGuideModel(
          id: 'p2',
          foodCanonicalName: 'dal',
          label: '1 bowl',
          grams: 250.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortionPickerWidget(
              portions: testPortions,
              initialMultiplier: 1.0,
              referenceCaloriesPer100g: 100.0, // 100 kcal per 100g = 1 kcal/g
              onPortionChanged: (portion, mult, grams, cals) {
                lastPortion = portion;
                lastMultiplier = mult;
                lastGrams = grams;
                lastCalories = cals;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify labels render
      expect(find.text('Portion Guide'), findsOneWidget);
      expect(find.text('1 katori'), findsOneWidget);
      expect(find.text('1 bowl'), findsOneWidget);
      expect(find.text('150 g'), findsWidgets);
      expect(find.text('1×'), findsOneWidget);

      // Tap '+' stepper to increase multiplier to 1.5×
      final addIcon = find.byIcon(Icons.add_circle_outline);
      expect(addIcon, findsOneWidget);
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      expect(find.text('1.5×'), findsOneWidget);
      // 1.5 × 150g = 225g
      expect(lastMultiplier, 1.5);
      expect(lastGrams, 225.0);
      expect(lastCalories, 225.0);

      // Select '1 bowl' (250g)
      await tester.tap(find.text('1 bowl'));
      await tester.pumpAndSettle();

      // 1.5 × 250g = 375g
      expect(lastPortion?.id, 'p2');
      expect(lastGrams, 375.0);
      expect(lastCalories, 375.0);

      // Tap '-' stepper to decrease multiplier back to 1.0×
      final removeIcon = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeIcon);
      await tester.pumpAndSettle();

      expect(find.text('1×'), findsOneWidget);
      expect(lastGrams, 250.0);
    });
  });
}
