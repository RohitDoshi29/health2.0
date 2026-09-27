import '../../core/config/api_constants.dart';
import '../models/analysis_model.dart';
import '../services/api_client.dart';

class AnalysisRepository {
  final ApiClient _apiClient;

  AnalysisRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<MealAnalysisResponseModel> analyzeFoodImage({
    required List<int> imageBytes,
    required String filename,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiConstants.analyze,
      bytes: imageBytes,
      filename: filename,
      fieldName: 'image',
    );
    return MealAnalysisResponseModel.fromJson(response);
  }
}

