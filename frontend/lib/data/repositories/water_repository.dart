import '../../core/config/api_constants.dart';
import '../models/water_model.dart';
import '../services/api_client.dart';

class WaterRepository {
  final ApiClient _apiClient;

  WaterRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<DailyWaterSummaryModel> getTodaySummary() async {
    try {
      final response = await _apiClient.get(ApiConstants.waterToday);
      return DailyWaterSummaryModel.fromJson(response);
    } catch (e) {
      return DailyWaterSummaryModel.initial();
    }
  }

  Future<DailyWaterSummaryModel> logWater(double amountMl) async {
    final payload = {'amount_ml': amountMl};
    try {
      final response = await _apiClient.post(ApiConstants.water, payload);
      return DailyWaterSummaryModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteLog(String logId) async {
    try {
      await _apiClient.delete('${ApiConstants.water}/$logId');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateWaterGoal(double waterTargetMl) async {
    final payload = {'water_target_ml': waterTargetMl};
    await _apiClient.put(ApiConstants.waterGoal, payload);
  }

  Future<List<WaterHistoryDayModel>> getHistory({int days = 7}) async {
    try {
      final response = await _apiClient.get('${ApiConstants.waterHistory}?days=$days');
      final list = response as List<dynamic>;
      return list.map((e) => WaterHistoryDayModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
