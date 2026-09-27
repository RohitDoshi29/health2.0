import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/barcode_model.dart';
import 'package:heathify_app/ui/core/widgets/barcode_result_dialog.dart';

void main() {
  group('BarcodeProductModel Tests', () {
    final sampleJson = {
      'barcode': '737628064502',
      'name': 'Organic Rolled Oats',
      'brand': 'Bob\'s Red Mill',
      'serving_size': '48 g (0.5 cup)',
      'serving_quantity': 48.0,
      'serving_unit': 'g',
      'calories': 190.0,
      'protein': 7.0,
      'carbohydrates': 32.0,
      'fat': 3.5,
      'fiber': 5.0,
      'sugars': 1.0,
      'sodium': 0.005,
      'nutriscore_grade': 'a',
      'nova_group': 1,
      'image_url': 'https://example.com/oats.jpg',
      'ingredients': 'Whole grain rolled oats.',
      'source': 'openfoodfacts',
    };

    test('parses from JSON correctly', () {
      final model = BarcodeProductModel.fromJson(sampleJson);
      expect(model.barcode, '737628064502');
      expect(model.name, 'Organic Rolled Oats');
      expect(model.brand, 'Bob\'s Red Mill');
      expect(model.calories, 190.0);
      expect(model.protein, 7.0);
      expect(model.nutriscoreGrade, 'a');
      expect(model.novaGroup, 1);
    });

    test('converts to MealItemAnalysisModel with multiplier', () {
      final model = BarcodeProductModel.fromJson(sampleJson);
      final item = model.toMealItemAnalysis(multiplier: 2.0);

      expect(item.name, 'Organic Rolled Oats (Bob\'s Red Mill)');
      expect(item.quantity, 96.0);
      expect(item.estimatedCalories, 380.0);
      expect(item.protein, 14.0);
      expect(item.carbohydrates, 64.0);
      expect(item.fat, 7.0);
      expect(item.fiber, 10.0);
    });
  });

  group('BarcodeResultDialog Widget Tests', () {
    const product = BarcodeProductModel(
      barcode: '737628064502',
      name: 'Organic Rolled Oats',
      brand: 'Bob\'s Red Mill',
      servingSize: '48 g',
      servingQuantity: 48.0,
      calories: 190.0,
      protein: 7.0,
      carbohydrates: 32.0,
      fat: 3.5,
      fiber: 5.0,
      nutriscoreGrade: 'a',
      novaGroup: 1,
    );

    testWidgets('renders product info, Nutri-Score, and calories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeResultDialog(
              product: product,
              onAddToPlate: (p, mult) {},
            ),
          ),
        ),
      );

      expect(find.text('Organic Rolled Oats'), findsOneWidget);
      expect(find.text('Bob\'s Red Mill'), findsOneWidget);
      expect(find.text('NUTRI-SCORE A'), findsOneWidget);
      expect(find.text('NOVA 1'), findsOneWidget);
      expect(find.text('190'), findsOneWidget);
      expect(find.text('Add to Current Meal Plate'), findsOneWidget);
    });

    testWidgets('stepper adjusts calories dynamically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeResultDialog(
              product: product,
              onAddToPlate: (p, mult) {},
            ),
          ),
        ),
      );

      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('190'), findsOneWidget);

      // Tap + button
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('1.5x'), findsOneWidget);
      expect(find.text('285'), findsOneWidget);
    });
  });
}

