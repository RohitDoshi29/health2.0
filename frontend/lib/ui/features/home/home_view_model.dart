import 'package:flutter/foundation.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/meal_model.dart';
import '../../../data/models/trend_model.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../../data/repositories/meal_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final MealRepository _mealRepository;
  final GoalRepository _goalRepository;

  List<MealModel> _meals = [];
  List<MealModel> get meals => _meals;

  DailyAnalyticsModel? _analytics;
  DailyAnalyticsModel? get analytics => _analytics;

  TrendsAnalyticsModel? _trends;
  TrendsAnalyticsModel? get trends => _trends;

  int _trendDays = 7;
  int get trendDays => _trendDays;

  bool _isTrendsLoading = false;
  bool get isTrendsLoading => _isTrendsLoading;

  GoalModel? _goal;
  GoalModel? get goal => _goal;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeViewModel({
    MealRepository? mealRepository,
    GoalRepository? goalRepository,
  })  : _mealRepository = mealRepository ?? MealRepository(),
        _goalRepository = goalRepository ?? GoalRepository();

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.isUtc ? a.toLocal() : a;
    final localB = b.isUtc ? b.toLocal() : b;
    return localA.year == localB.year && localA.month == localB.month && localA.day == localB.day;
  }

  double get todayCalories {
    final now = DateTime.now();
    return _meals.where((m) => _isSameDay(m.createdAt, now)).fold(0.0, (sum, m) => sum + m.totalCalories);
  }

  double get todayProtein {
    final now = DateTime.now();
    return _meals.where((m) => _isSameDay(m.createdAt, now)).fold(0.0, (sum, m) => sum + m.totalProtein);
  }

  double get todayCarbs {
    final now = DateTime.now();
    return _meals.where((m) => _isSameDay(m.createdAt, now)).fold(0.0, (sum, m) => sum + m.totalCarbohydrates);
  }

  double get todayFat {
    final now = DateTime.now();
    return _meals.where((m) => _isSameDay(m.createdAt, now)).fold(0.0, (sum, m) => sum + m.totalFat);
  }

  double get todayFiber {
    final now = DateTime.now();
    return _meals.where((m) => _isSameDay(m.createdAt, now)).fold(0.0, (sum, m) => sum + m.totalFiber);
  }

  Future<void> loadDashboard() => loadMeals();

  Future<void> loadMeals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tzOffset = now.timeZoneOffset.inMinutes;

    try {
      final results = await Future.wait([
        _mealRepository.listMeals(),
        _goalRepository.getDailyAnalytics(date: todayStr, tzOffset: tzOffset),
        _goalRepository.getTrendsAnalytics(days: _trendDays, tzOffset: tzOffset),
      ]);
      _meals = results[0] as List<MealModel>;
      _analytics = results[1] as DailyAnalyticsModel;
      _trends = results[2] as TrendsAnalyticsModel;
      _goal = _analytics?.goal;

      // Ensure analytics reflects logged meals even if timezones diverge
      if (_analytics != null && todayCalories > 0 && (_analytics!.consumedCalories == 0 || (_analytics!.consumedCalories < todayCalories))) {
        final goal = _analytics!.goal;
        final calProg = goal.calorieTarget > 0 ? (todayCalories / goal.calorieTarget) : 0.0;
        final protProg = goal.proteinTarget > 0 ? (todayProtein / goal.proteinTarget) : 0.0;
        final carbsProg = goal.carbohydratesTarget > 0 ? (todayCarbs / goal.carbohydratesTarget) : 0.0;
        final fatProg = goal.fatTarget > 0 ? (todayFat / goal.fatTarget) : 0.0;
        final fiberProg = goal.fiberTarget > 0 ? (todayFiber / goal.fiberTarget) : 0.0;

        _analytics = DailyAnalyticsModel(
          date: _analytics!.date,
          consumedCalories: todayCalories,
          consumedProtein: todayProtein,
          consumedCarbohydrates: todayCarbs,
          consumedFat: todayFat,
          consumedFiber: todayFiber,
          calorieProgress: calProg,
          proteinProgress: protProg,
          carbohydratesProgress: carbsProg,
          fatProgress: fatProg,
          fiberProgress: fiberProg,
          mealsCount: _meals.where((m) => _isSameDay(m.createdAt, now)).length,
          goal: goal,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrends(int days) async {
    _trendDays = days;
    _isTrendsLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final tzOffset = now.timeZoneOffset.inMinutes;

    try {
      _trends = await _goalRepository.getTrendsAnalytics(days: days, tzOffset: tzOffset);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isTrendsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoal({
    double? calorieTarget,
    double? proteinTarget,
    double? carbohydratesTarget,
    double? fatTarget,
    double? fiberTarget,
    double? waterTargetMl,
  }) =>
      updateGoals(
        calorieTarget: calorieTarget,
        proteinTarget: proteinTarget,
        carbohydratesTarget: carbohydratesTarget,
        fatTarget: fatTarget,
        fiberTarget: fiberTarget,
        waterTargetMl: waterTargetMl,
      );

  Future<void> updateGoals({
    double? calorieTarget,
    double? proteinTarget,
    double? carbohydratesTarget,
    double? fatTarget,
    double? fiberTarget,
    double? waterTargetMl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tzOffset = now.timeZoneOffset.inMinutes;

    try {
      final payload = <String, dynamic>{};
      if (calorieTarget != null) payload['calorie_target'] = calorieTarget;
      if (proteinTarget != null) payload['protein_target'] = proteinTarget;
      if (carbohydratesTarget != null) payload['carbohydrates_target'] = carbohydratesTarget;
      if (fatTarget != null) payload['fat_target'] = fatTarget;
      if (fiberTarget != null) payload['fiber_target'] = fiberTarget;
      if (waterTargetMl != null) payload['water_target_ml'] = waterTargetMl;

      _goal = await _goalRepository.updateMyGoals(payload);
      _analytics = await _goalRepository.getDailyAnalytics(date: todayStr, tzOffset: tzOffset);
      _trends = await _goalRepository.getTrendsAnalytics(days: _trendDays, tzOffset: tzOffset);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMeal(String mealId) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tzOffset = now.timeZoneOffset.inMinutes;

    try {
      await _mealRepository.deleteMeal(mealId);
      _meals.removeWhere((m) => m.id == mealId);
      _analytics = await _goalRepository.getDailyAnalytics(date: todayStr, tzOffset: tzOffset);
      _trends = await _goalRepository.getTrendsAnalytics(days: _trendDays, tzOffset: tzOffset);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<MealModel> relogMeal(String mealId) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tzOffset = now.timeZoneOffset.inMinutes;

    final newMeal = await _mealRepository.relogMeal(mealId, tzOffset: tzOffset);
    _meals.insert(0, newMeal);
    try {
      _analytics = await _goalRepository.getDailyAnalytics(date: todayStr, tzOffset: tzOffset);
      _trends = await _goalRepository.getTrendsAnalytics(days: _trendDays, tzOffset: tzOffset);
    } catch (_) {}
    notifyListeners();
    return newMeal;
  }
}
