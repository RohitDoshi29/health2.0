import '../../core/config/api_constants.dart';
import '../models/analysis_model.dart';
import '../models/favorite_model.dart';
import '../models/meal_model.dart';
import '../services/api_client.dart';

class FavoriteRepository {
  final ApiClient _apiClient;

  FavoriteRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<FavoriteModel>> getFavorites() async {
    final response = await _apiClient.get(ApiConstants.favorites);
    if (response is List) {
      return response
          .map((item) => FavoriteModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<FavoriteModel> createFavorite({
    required String name,
    required String mealType,
    required List<MealItemAnalysisModel> items,
  }) async {
    final payload = {
      'name': name.trim(),
      'meal_type': mealType,
      'items': items
          .map((i) => {
                'food_id': i.matchedFoodId,
                'food_name': i.name,
                'quantity': i.quantity,
                'unit': i.unit,
                'calories': i.estimatedCalories,
                'protein': i.protein,
                'carbohydrates': i.carbohydrates,
                'fat': i.fat,
                'fiber': i.fiber,
              })
          .toList(),
    };

    final response = await _apiClient.post(ApiConstants.favorites, payload);
    return FavoriteModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteFavorite(String id) async {
    await _apiClient.delete('${ApiConstants.favorites}/$id');
  }

  Future<MealModel> quickLogFavorite(String id) async {
    final response = await _apiClient.post('${ApiConstants.favorites}/$id/log', {});
    return MealModel.fromJson(response as Map<String, dynamic>);
  }
}

