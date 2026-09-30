import '../../core/config/api_constants.dart';
import '../models/profile_model.dart';
import '../services/api_client.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<UserProfileResponseModel> getProfile() async {
    final response = await _apiClient.get(ApiConstants.profile);
    return UserProfileResponseModel.fromJson(response);
  }

  Future<UserProfileResponseModel> saveProfile(Map<String, dynamic> profilePayload) async {
    final response = await _apiClient.post(ApiConstants.profile, profilePayload);
    return UserProfileResponseModel.fromJson(response);
  }

  Future<NutritionTargetsModel> previewProfile(Map<String, dynamic> profilePayload) async {
    final response = await _apiClient.post(ApiConstants.profilePreview, profilePayload);
    return NutritionTargetsModel.fromJson(response);
  }
}
