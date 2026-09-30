import 'dart:math';
import '../../core/config/api_constants.dart';
import '../models/analysis_model.dart';
import '../models/meal_model.dart';
import '../models/nutrition_model.dart';
import '../models/portion_model.dart';
import '../models/recent_food_model.dart';
import '../services/api_client.dart';
import '../services/local_storage_service.dart';
import '../services/sync_manager.dart';

class MealRepository {
  final ApiClient _apiClient;
  final LocalStorageService _storage;
  final SyncManager? _syncManager;

  MealRepository({
    ApiClient? apiClient,
    LocalStorageService? storage,
    SyncManager? syncManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? LocalStorageService(),
        _syncManager = syncManager;

  Future<MealModel> saveMeal({
    required String mealType,
    required List<MealItemAnalysisModel> items,
    String? imageUrl,
  }) async {
    final now = DateTime.now();
    final payload = {
      'meal_type': mealType,
      'image_url': imageUrl,
      'created_at': now.toUtc().toIso8601String(),
      'items': items.map((i) => i.toMealItemCreateJson()).toList(),
    };

    try {
      final response = await _apiClient.post(ApiConstants.meals, payload);
      final meal = MealModel.fromJson(response);

      // Update local cache
      final cached = await _storage.getCachedMeals();
      cached.removeWhere((m) => m.id == meal.id);
      cached.insert(0, meal);
      await _storage.saveCachedMeals(cached);

      return meal;
    } catch (e) {
      // Offline fallback: create local meal representation and enqueue sync action
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final localMeal = MealModel(
        id: localId,
        userId: 'current_user',
        imageUrl: imageUrl,
        mealType: mealType,
        totalCalories: items.fold(0.0, (s, i) => s + i.estimatedCalories),
        totalProtein: items.fold(0.0, (s, i) => s + i.protein),
        totalCarbohydrates: items.fold(0.0, (s, i) => s + i.carbohydrates),
        totalFat: items.fold(0.0, (s, i) => s + i.fat),
        totalFiber: items.fold(0.0, (s, i) => s + i.fiber),
        createdAt: now,
        updatedAt: now,
        items: items.map((i) => MealItemModel(
          id: 'item_${Random().nextInt(99999)}',
          foodId: i.matchedFoodId,
          foodName: i.name,
          quantity: i.quantity,
          unit: i.unit,
          calories: i.estimatedCalories,
          protein: i.protein,
          carbohydrates: i.carbohydrates,
          fat: i.fat,
          fiber: i.fiber,
          confidence: i.confidence,
          createdAt: now,
        )).toList(),
      );

      final cached = await _storage.getCachedMeals();
      cached.insert(0, localMeal);
      await _storage.saveCachedMeals(cached);

      final action = {
        'id': 'action_${DateTime.now().millisecondsSinceEpoch}',
        'action': 'CREATE',
        'temp_meal_id': localId,
        'payload': payload,
        'created_at': now.toUtc().toIso8601String(),
      };
      await _storage.addPendingSyncAction(action);
      await _syncManager?.refreshPendingCount();

      return localMeal;
    }
  }

  Future<List<MealModel>> listMeals({int limit = 50, int offset = 0}) async {
    try {
      final response = await _apiClient.get('${ApiConstants.meals}?limit=$limit&offset=$offset');
      final meals = (response as List<dynamic>)
          .map((e) => MealModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Update local cache
      await _storage.saveCachedMeals(meals);
      return meals;
    } catch (e) {
      // Offline fallback: return cached meals
      return await _storage.getCachedMeals();
    }
  }

  Future<MealModel> getMeal(String mealId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.meals}/$mealId');
      return MealModel.fromJson(response);
    } catch (e) {
      final cached = await _storage.getCachedMeals();
      return cached.firstWhere(
        (m) => m.id == mealId,
        orElse: () => throw Exception('Meal not found in local cache'),
      );
    }
  }

  Future<void> deleteMeal(String mealId) async {
    // Delete from local cache immediately
    final cached = await _storage.getCachedMeals();
    cached.removeWhere((m) => m.id == mealId);
    await _storage.saveCachedMeals(cached);

    try {
      await _apiClient.delete('${ApiConstants.meals}/$mealId');
    } catch (e) {
      // Queue offline delete if this is not a purely local meal
      if (!mealId.startsWith('local_')) {
        final action = {
          'id': 'action_del_${DateTime.now().millisecondsSinceEpoch}',
          'action': 'DELETE',
          'meal_id': mealId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        await _storage.addPendingSyncAction(action);
        await _syncManager?.refreshPendingCount();
      }
    }
  }

  Future<List<FoodItemModel>> searchFoods(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      return listFoods(limit: 20);
    }
    try {
      final response = await _apiClient.get('${ApiConstants.foods}/search?q=${Uri.encodeComponent(clean)}');
      if (response is List) {
        return response.map((item) => FoodItemModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodItemModel>> listFoods({int limit = 50}) async {
    try {
      final response = await _apiClient.get('${ApiConstants.foods}?limit=$limit');
      if (response is List) {
        return response.map((item) => FoodItemModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<RecentFoodModel>> getRecentFoods({int limit = 20}) async {
    try {
      final response = await _apiClient.get('${ApiConstants.recentFoods}?limit=$limit');
      if (response is List) {
        return response.map((item) => RecentFoodModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<MealModel> relogMeal(String mealId, {int? tzOffset}) async {
    final offset = tzOffset ?? DateTime.now().timeZoneOffset.inMinutes;
    final response = await _apiClient.post('${ApiConstants.relogMeal(mealId)}?tz_offset=$offset', {});
    final meal = MealModel.fromJson(response as Map<String, dynamic>);

    // Update local cache
    final cached = await _storage.getCachedMeals();
    cached.removeWhere((m) => m.id == meal.id);
    cached.insert(0, meal);
    await _storage.saveCachedMeals(cached);

    return meal;
  }

  Future<List<PortionGuideModel>> getPortionsForFood(String foodId) async {
    try {
      final response = await _apiClient.get(ApiConstants.foodPortions(foodId));
      if (response is List) {
        return response
            .map((item) => PortionGuideModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<PortionGuideModel>> searchPortions({String? query}) async {
    try {
      final uri = (query != null && query.trim().isNotEmpty)
          ? '${ApiConstants.portions}?q=${Uri.encodeComponent(query.trim())}'
          : ApiConstants.portions;
      final response = await _apiClient.get(uri);
      if (response is List) {
        return response
            .map((item) => PortionGuideModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}


