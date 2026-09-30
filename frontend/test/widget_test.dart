import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/meal_model.dart';
import 'package:heathify_app/ui/core/widgets/custom_button.dart';
import 'package:heathify_app/ui/core/widgets/macro_card.dart';
import 'package:heathify_app/ui/core/widgets/meal_photo_viewer_dialog.dart';
import 'package:heathify_app/ui/core/widgets/water_tracker_card.dart';
import 'package:heathify_app/data/services/sync_manager.dart';
import 'package:heathify_app/ui/features/auth/auth_view_model.dart';
import 'package:heathify_app/ui/features/home/home_view.dart';
import 'package:heathify_app/ui/features/home/home_view_model.dart';
import 'package:heathify_app/ui/features/settings/info_view.dart';
import 'package:heathify_app/ui/features/settings/settings_view.dart';
import 'package:heathify_app/ui/features/water/water_view_model.dart';
import 'package:heathify_app/ui/features/weight/weight_view_model.dart';
import 'package:heathify_app/ui/features/streak/streak_view_model.dart';
import 'package:heathify_app/ui/features/weekly/weekly_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  group('UI Widgets Tests', () {
    testWidgets('MacroCard displays all calories and macros', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MacroCard(
              calories: 520.0,
              protein: 42.5,
              carbs: 65.0,
              fat: 14.2,
              fiber: 8.0,
            ),
          ),
        ),
      );

      expect(find.text('520'), findsOneWidget);
      expect(find.text('kcal'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('42.5g'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('65.0g'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('14.2g'), findsOneWidget);
      expect(find.text('Fiber'), findsOneWidget);
      expect(find.text('8.0g'), findsOneWidget);
    });

    testWidgets('CustomButton handles tap and loading states', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Save Meal',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Save Meal'), findsOneWidget);
      await tester.tap(find.text('Save Meal'));
      expect(tapped, isTrue);

      // Loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Save Meal',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Meal'), findsNothing);
    });

    testWidgets('MealPhotoViewerDialog renders meal details and macros', (WidgetTester tester) async {
      final now = DateTime(2026, 9, 22, 13, 30);
      final testMeal = MealModel(
        id: 'test-meal-1',
        userId: 'user-1',
        mealType: 'lunch',
        totalCalories: 450,
        totalProtein: 35,
        totalCarbohydrates: 40,
        totalFat: 12,
        totalFiber: 6,
        createdAt: now,
        updatedAt: now,
        items: [
          MealItemModel(
            id: 'item-1',
            foodName: 'Grilled Chicken Salad',
            quantity: 250,
            unit: 'g',
            calories: 450,
            protein: 35,
            carbohydrates: 40,
            fat: 12,
            fiber: 6,
            createdAt: now,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealPhotoViewerDialog(meal: testMeal),
          ),
        ),
      );

      expect(find.text('LUNCH'), findsOneWidget);
      expect(find.text('450 kcal'), findsOneWidget);
      expect(find.text('35.0g'), findsOneWidget);
      expect(find.text('40.0g'), findsOneWidget);
      expect(find.text('12.0g'), findsOneWidget);
      expect(find.text('Grilled Chicken Salad (250g)'), findsOneWidget);
    });

    testWidgets('WaterTrackerCard renders hydration progress and quick add buttons', (WidgetTester tester) async {
      final waterVm = WaterViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<WaterViewModel>.value(
              value: waterVm,
              child: const WaterTrackerCard(),
            ),
          ),
        ),
      );

      expect(find.text('Hydration'), findsOneWidget);
      expect(find.text('0 / 2500 ml'), findsOneWidget);
      expect(find.text('0% completed'), findsOneWidget);
      expect(find.text('+250 ml'), findsOneWidget);
      expect(find.text('+500 ml'), findsOneWidget);
      expect(find.text('+750 ml'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('InfoView renders app version, mission, and medical disclaimer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InfoView(),
        ),
      );

      expect(find.text('Heathify'), findsOneWidget);
      expect(find.text('Version 1.2.0 (Build 2026)'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Core Technologies'), findsOneWidget);
      expect(find.text('Medical & Nutrition Disclaimer'), findsOneWidget);
    });

    testWidgets('SettingsView renders user profile and settings sections', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
            ChangeNotifierProvider(create: (_) => HomeViewModel()),
            ChangeNotifierProvider(create: (_) => WaterViewModel()),
            ChangeNotifierProvider(create: (_) => StreakViewModel()),
            ChangeNotifierProvider(create: (_) => SyncManager()),
          ],
          child: const MaterialApp(
            home: SettingsView(),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Nutrition & Hydration Targets'), findsOneWidget);
      expect(find.text('Data & Connectivity'), findsOneWidget);
      expect(find.text('About & Support'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('HomeView has Info destination in bottom navigation bar and profile logo in AppBar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
            ChangeNotifierProvider(create: (_) => HomeViewModel()),
            ChangeNotifierProvider(create: (_) => WaterViewModel()),
            ChangeNotifierProvider(create: (_) => WeightViewModel()),
            ChangeNotifierProvider(create: (_) => StreakViewModel()),
            ChangeNotifierProvider(create: (_) => WeeklyViewModel()),
            ChangeNotifierProvider(create: (_) => SyncManager()),
          ],
          child: const MaterialApp(
            home: HomeView(),
          ),
        ),
      );
      await tester.pump();

      // Verify 5 bottom navigation bar destinations
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Scan Food'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify profile logo tooltip / widget exists in AppBar
      expect(find.byTooltip('Profile & Settings'), findsOneWidget);
    });
  });
}
