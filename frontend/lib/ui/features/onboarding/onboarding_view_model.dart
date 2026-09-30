import 'package:flutter/foundation.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';

class OnboardingViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepo;

  OnboardingViewModel({ProfileRepository? profileRepository})
      : _profileRepo = profileRepository ?? ProfileRepository();

  int _currentStep = 1;
  int get currentStep => _currentStep;

  int _age = 25;
  int get age => _age;

  String _sex = 'male';
  String get sex => _sex;

  double _heightCm = 175.0;
  double get heightCm => _heightCm;

  double _weightKg = 70.0;
  double get weightKg => _weightKg;

  String _activityLevel = 'moderate';
  String get activityLevel => _activityLevel;

  String _goal = 'maintain';
  String get goal => _goal;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  NutritionTargetsModel? _previewTargets;
  NutritionTargetsModel? get previewTargets => _previewTargets;

  void setAge(int val) {
    if (val >= 13 && val <= 100) {
      _age = val;
      notifyListeners();
    }
  }

  void setSex(String val) {
    _sex = val;
    notifyListeners();
  }

  void setHeight(double val) {
    _heightCm = val;
    notifyListeners();
  }

  void setWeight(double val) {
    _weightKg = val;
    notifyListeners();
  }

  void setActivityLevel(String val) {
    _activityLevel = val;
    notifyListeners();
  }

  void setGoal(String val) {
    _goal = val;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    } else if (_currentStep == 3) {
      _calculateAndShowResults();
    }
  }

  void prevStep() {
    if (_currentStep > 1) {
      _currentStep--;
      notifyListeners();
    }
  }

  Future<void> loadCurrentProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _profileRepo.getProfile();
      _age = res.profile.age;
      _sex = res.profile.sex;
      _heightCm = res.profile.heightCm;
      _weightKg = res.profile.weightKg;
      _activityLevel = res.profile.activityLevel;
      _goal = res.profile.goal;
      _currentStep = 1;
    } catch (_) {
      // Keep defaults if not found
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _calculateAndShowResults() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'age': _age,
        'sex': _sex,
        'height_cm': _heightCm,
        'weight_kg': _weightKg,
        'activity_level': _activityLevel,
        'goal': _goal,
      };
      _previewTargets = await _profileRepo.previewProfile(payload);
      _currentStep = 4; // Result screen
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'age': _age,
        'sex': _sex,
        'height_cm': _heightCm,
        'weight_kg': _weightKg,
        'activity_level': _activityLevel,
        'goal': _goal,
      };
      await _profileRepo.saveProfile(payload);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
