import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_model.dart';

class LocalStorageService {
  static const String _keyCachedMeals = 'heathify_cached_meals';
  static const String _keyPendingActions = 'heathify_pending_sync_actions';
  static const String _keyLastSync = 'heathify_last_sync_timestamp';

  final SharedPreferences? _prefs;

  LocalStorageService({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  Future<List<MealModel>> getCachedMeals() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyCachedMeals);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => MealModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedMeals(List<MealModel> meals) async {
    final prefs = await _instance;
    final jsonList = meals.map((m) {
      return {
        'id': m.id,
        'user_id': m.userId,
        'image_url': m.imageUrl,
        'meal_type': m.mealType,
        'total_calories': m.totalCalories,
        'total_protein': m.totalProtein,
        'total_carbohydrates': m.totalCarbohydrates,
        'total_fat': m.totalFat,
        'total_fiber': m.totalFiber,
        'created_at': m.createdAt.toIso8601String(),
        'updated_at': m.updatedAt.toIso8601String(),
        'items': m.items.map((i) => {
          'id': i.id,
          'food_id': i.foodId,
          'food_name': i.foodName,
          'quantity': i.quantity,
          'unit': i.unit,
          'calories': i.calories,
          'protein': i.protein,
          'carbohydrates': i.carbohydrates,
          'fat': i.fat,
          'fiber': i.fiber,
          'confidence': i.confidence,
          'created_at': i.createdAt.toIso8601String(),
        }).toList(),
      };
    }).toList();

    await prefs.setString(_keyCachedMeals, jsonEncode(jsonList));
  }

  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyPendingActions);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> addPendingSyncAction(Map<String, dynamic> action) async {
    final prefs = await _instance;
    final current = await getPendingSyncActions();
    current.add(action);
    await prefs.setString(_keyPendingActions, jsonEncode(current));
  }

  Future<void> removePendingSyncAction(String actionId) async {
    final prefs = await _instance;
    final current = await getPendingSyncActions();
    current.removeWhere((a) => a['id'] == actionId);
    await prefs.setString(_keyPendingActions, jsonEncode(current));
  }

  Future<void> clearPendingSyncActions() async {
    final prefs = await _instance;
    await prefs.remove(_keyPendingActions);
  }

  Future<void> clearCachedMeals() async {
    final prefs = await _instance;
    await prefs.remove(_keyCachedMeals);
  }

  Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.remove(_keyCachedMeals);
    await prefs.remove(_keyPendingActions);
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyLastSync);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await _instance;
    await prefs.setString(_keyLastSync, timestamp.toIso8601String());
  }
}

