import '../../core/config/api_constants.dart';
import '../models/weekly_model.dart';
import '../services/api_client.dart';

class WeeklyRepository {
  final ApiClient _apiClient;

  WeeklyRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<WeeklyReportResponseModel> getWeeklyReport({
    int weekOffset = 0,
    int? tzOffset,
  }) async {
    final offset = tzOffset ?? DateTime.now().timeZoneOffset.inMinutes;
    final endpoint =
        '${ApiConstants.weeklyReport}?week_offset=$weekOffset&tz_offset=$offset';
    final response = await _apiClient.get(endpoint);
    return WeeklyReportResponseModel.fromJson(response);
  }
}
