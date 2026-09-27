import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/analysis_model.dart';
import 'package:heathify_app/ui/core/widgets/image_bounding_box_overlay.dart';

void main() {
  group('BoundingBoxModel & Analysis Serialization Tests', () {
    test('BoundingBoxModel serialization and deserialization', () {
      final json = {
        'ymin': 0.12,
        'xmin': 0.34,
        'ymax': 0.78,
        'xmax': 0.90,
      };

      final box = BoundingBoxModel.fromJson(json);
      expect(box.ymin, 0.12);
      expect(box.xmin, 0.34);
      expect(box.ymax, 0.78);
      expect(box.xmax, 0.90);

      final outJson = box.toJson();
      expect(outJson['ymin'], 0.12);
      expect(outJson['xmax'], 0.90);
    });

    test('MealAnalysisResponseModel parses bounding boxes', () {
      final json = {
        'total': {
          'estimated_calories': 400.0,
          'protein': 30.0,
          'carbohydrates': 40.0,
          'fat': 10.0,
          'fiber': 5.0,
        },
        'items': [
          {
            'name': 'Grilled Salmon',
            'quantity': 200,
            'unit': 'g',
            'estimated_calories': 400.0,
            'protein': 30.0,
            'carbohydrates': 0.0,
            'fat': 10.0,
            'fiber': 0.0,
            'confidence': 0.95,
            'matched_food_id': 'food-123',
            'bounding_box': {
              'ymin': 0.2,
              'xmin': 0.2,
              'ymax': 0.8,
              'xmax': 0.8,
            },
          }
        ],
        'disclaimer': 'Estimates only',
      };

      final response = MealAnalysisResponseModel.fromJson(json);
      expect(response.items.length, 1);
      final item = response.items.first;
      expect(item.name, 'Grilled Salmon');
      expect(item.boundingBox, isNotNull);
      expect(item.boundingBox!.ymin, 0.2);
      expect(item.boundingBox!.xmax, 0.8);
    });
  });

  group('ImageBoundingBoxOverlay Widget Tests', () {
    testWidgets('renders placeholder when imageBytes is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImageBoundingBoxOverlay(
              imageBytes: null,
              items: [],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('renders tags and triggers selection callbacks', (tester) async {
      // 1x1 transparent PNG bytes for testing Image.memory widget
      final testPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x60, 0x60, 0x00,
        0x00, 0x00, 0x05, 0x00, 0x01, 0xA5, 0x3F, 0xBF, 0x4A, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final items = [
        MealItemAnalysisModel(
          name: 'Steamed Broccoli',
          quantity: 150,
          unit: 'g',
          estimatedCalories: 50,
          protein: 4,
          carbohydrates: 10,
          fat: 0.5,
          fiber: 3.5,
          confidence: 0.92,
          boundingBox: const BoundingBoxModel(
            ymin: 0.1,
            xmin: 0.1,
            ymax: 0.5,
            xmax: 0.5,
          ),
        ),
      ];

      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageBoundingBoxOverlay(
                imageBytes: testPngBytes,
                items: items,
                onItemSelected: (idx) {
                  tappedIndex = idx;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Steamed Broccoli'), findsNWidgets(2)); // in overlay tag and chip
      expect(find.text('92%'), findsOneWidget);

      await tester.tap(find.text('Steamed Broccoli').first);
      expect(tappedIndex, 0);
    });
  });
}
