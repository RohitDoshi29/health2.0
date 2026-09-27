import '../../core/config/api_constants.dart';
import '../models/goal_model.dart';
import '../models/trend_model.dart';
import '../services/api_client.dart';

class GoalRepository {
  final ApiClient _apiClient;

  GoalRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<GoalModel> getMyGoals() async {
    final response = await _apiClient.get(ApiConstants.goals);
    return GoalModel.fromJson(response);
  }

  Future<GoalModel> updateMyGoals(Map<String, dynamic> goalsPayload) async {
    final response = await _apiClient.put(ApiConstants.goals, goalsPayload);
    return GoalModel.fromJson(response);
  }

  Future<DailyAnalyticsModel> getDailyAnalytics({String? date, int? tzOffset}) async {
    final offset = tzOffset ?? DateTime.now().timeZoneOffset.inMinutes;
    final dateParam = date != null ? '&date=$date' : '';
    final endpoint = '${ApiConstants.dailyAnalytics}?tz_offset=$offset$dateParam';
    final response = await _apiClient.get(endpoint);
    return DailyAnalyticsModel.fromJson(response);
  }

  Future<TrendsAnalyticsModel> getTrendsAnalytics({int days = 7, int? tzOffset}) async {
    final offset = tzOffset ?? DateTime.now().timeZoneOffset.inMinutes;
    final endpoint = '${ApiConstants.trendsAnalytics}?days=$days&tz_offset=$offset';
    final response = await _apiClient.get(endpoint);
    return TrendsAnalyticsModel.fromJson(response);
  }
}
