import '../../core/config/api_constants.dart';
import '../models/weight_model.dart';
import '../services/api_client.dart';

class WeightRepository {
  final ApiClient _apiClient;

  WeightRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<WeightLogModel> logWeight(
    double weightKg, {
    String? note,
    DateTime? loggedAt,
  }) async {
    final payload = <String, dynamic>{
      'weight_kg': weightKg,
      if (note != null && note.isNotEmpty) 'note': note,
      if (loggedAt != null) 'logged_at': loggedAt.toIso8601String(),
    };
    final response = await _apiClient.post(ApiConstants.weight, payload);
    return WeightLogModel.fromJson(response);
  }

  Future<WeightHistoryResponseModel> getWeightHistory({
    int days = 30,
    int? tzOffset,
  }) async {
    final offset = tzOffset ?? DateTime.now().timeZoneOffset.inMinutes;
    final endpoint = '${ApiConstants.weightHistory}?days=$days&tz_offset=$offset';
    final response = await _apiClient.get(endpoint);
    return WeightHistoryResponseModel.fromJson(response);
  }

  Future<void> deleteWeight(String id) async {
    await _apiClient.delete('${ApiConstants.weight}/$id');
  }
}
