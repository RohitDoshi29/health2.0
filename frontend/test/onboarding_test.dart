import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/profile_model.dart';
import 'package:heathify_app/data/models/user_model.dart';
import 'package:heathify_app/ui/features/onboarding/onboarding_view_model.dart';

void main() {
  group('Onboarding & Profile Models Tests', () {
    test('UserModel onboardingCompleted serialization', () {
      final jsonFalse = {
        'id': 'user-1',
        'name': 'Test',
        'email': 'test@example.com',
        'onboarding_completed': false,
      };
      final user1 = UserModel.fromJson(jsonFalse);
      expect(user1.onboardingCompleted, false);

      final jsonTrue = {
        'id': 'user-2',
        'name': 'Test 2',
        'email': 'test2@example.com',
        'onboarding_completed': true,
      };
      final user2 = UserModel.fromJson(jsonTrue);
      expect(user2.onboardingCompleted, true);
    });

    test('NutritionTargetsModel deserialization', () {
      final json = {
        'bmr': 1673.8,
        'tdee': 2594.4,
        'calorie_target': 2094.0,
        'protein_target': 120.0,
        'carbohydrates_target': 250.0,
        'fat_target': 58.2,
        'fiber_target': 29.3,
        'water_target_ml': 2625.0,
      };

      final targets = NutritionTargetsModel.fromJson(json);
      expect(targets.bmr, 1673.8);
      expect(targets.tdee, 2594.4);
      expect(targets.calorieTarget, 2094.0);
      expect(targets.proteinTarget, 120.0);
      expect(targets.carbohydratesTarget, 250.0);
      expect(targets.fatTarget, 58.2);
      expect(targets.fiberTarget, 29.3);
      expect(targets.waterTargetMl, 2625.0);
    });

    test('UserProfileModel serialization and deserialization', () {
      final json = {
        'id': 'prof-1',
        'user_id': 'user-1',
        'age': 25,
        'sex': 'male',
        'height_cm': 175.0,
        'weight_kg': 70.0,
        'activity_level': 'moderate',
        'goal': 'maintain',
        'onboarding_completed': true,
        'bmr': 1673.8,
        'tdee': 2594.4,
      };

      final profile = UserProfileModel.fromJson(json);
      expect(profile.age, 25);
      expect(profile.sex, 'male');
      expect(profile.heightCm, 175.0);
      expect(profile.weightKg, 70.0);
      expect(profile.activityLevel, 'moderate');
      expect(profile.goal, 'maintain');
      expect(profile.onboardingCompleted, true);

      final outJson = profile.toJson();
      expect(outJson['age'], 25);
      expect(outJson['sex'], 'male');
      expect(outJson['height_cm'], 175.0);
      expect(outJson['weight_kg'], 70.0);
    });
  });

  group('OnboardingViewModel State Tests', () {
    test('Initial step is 1 and setters update state', () {
      final vm = OnboardingViewModel();
      expect(vm.currentStep, 1);

      vm.setAge(30);
      expect(vm.age, 30);

      vm.setSex('female');
      expect(vm.sex, 'female');

      vm.setHeight(165.0);
      expect(vm.heightCm, 165.0);

      vm.setWeight(58.0);
      expect(vm.weightKg, 58.0);

      vm.setActivityLevel('active');
      expect(vm.activityLevel, 'active');

      vm.setGoal('lose');
      expect(vm.goal, 'lose');
    });

    test('Step navigation bounds', () {
      final vm = OnboardingViewModel();
      expect(vm.currentStep, 1);

      vm.nextStep();
      expect(vm.currentStep, 2);

      vm.nextStep();
      expect(vm.currentStep, 3);

      vm.prevStep();
      expect(vm.currentStep, 2);

      vm.prevStep();
      expect(vm.currentStep, 1);

      // Cannot go below step 1
      vm.prevStep();
      expect(vm.currentStep, 1);
    });
  });
}
