import '../../core/config/api_constants.dart';
import '../models/streak_model.dart';
import '../services/api_client.dart';

class StreakRepository {
  final ApiClient _apiClient;

  StreakRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<StreaksResponseModel> getStreaks({int? tzOffset}) async {
    final offset = tzOffset ?? DateTime.now().timeZoneOffset.inMinutes;
    final endpoint = '${ApiConstants.streaks}?tz_offset=$offset';
    final response = await _apiClient.get(endpoint);
    return StreaksResponseModel.fromJson(response);
  }
}
