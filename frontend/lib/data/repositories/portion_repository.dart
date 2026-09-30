import '../../core/config/api_constants.dart';
import '../models/portion_model.dart';
import '../services/api_client.dart';

class PortionRepository {
  final ApiClient _apiClient;

  PortionRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve registered portion guides for a specific food by its ID.
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

  /// Search portions by food canonical name or label.
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
