import '../../core/config/api_constants.dart';
import '../../core/utils/token_storage.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/google_auth_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final GoogleAuthService _googleAuthService;

  AuthRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    GoogleAuthService? googleAuthService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _googleAuthService = googleAuthService ?? GoogleAuthService();

  Future<AuthResponseModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.signup,
      {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await _tokenStorage.saveToken(authResponse.accessToken);
    return authResponse;
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      {
        'email': email,
        'password': password,
      },
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await _tokenStorage.saveToken(authResponse.accessToken);
    return authResponse;
  }

  Future<AuthResponseModel> authenticateWithGoogleToken({
    required String idToken,
    required String email,
    String? name,
    String? avatarUrl,
    String? firebaseUid,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.googleAuth,
      {
        'id_token': idToken,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
        'firebase_uid': firebaseUid,
      },
    );
    final authResponse = AuthResponseModel.fromJson(response);
    await _tokenStorage.saveToken(authResponse.accessToken);
    return authResponse;
  }

  Future<AuthResponseModel?> signInWithGoogle() async {
    final googleResult = await _googleAuthService.signIn();
    if (googleResult == null) {
      return null;
    }

    return authenticateWithGoogleToken(
      idToken: googleResult.idToken,
      email: googleResult.email,
      name: googleResult.displayName,
      avatarUrl: googleResult.photoUrl,
      firebaseUid: googleResult.firebaseUid,
    );
  }

  Future<AuthResponseModel> signInWithGoogleDirect({
    required String email,
    String? name,
    String? avatarUrl,
  }) async {
    final mockToken = 'mock_google_oauth_token_${DateTime.now().millisecondsSinceEpoch}';
    return authenticateWithGoogleToken(
      idToken: mockToken,
      email: email,
      name: name ?? email.split('@')[0],
      avatarUrl: avatarUrl ?? 'https://lh3.googleusercontent.com/a/default-avatar',
      firebaseUid: 'uid_${email.hashCode.abs()}',
    );
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.get(ApiConstants.me);
    return UserModel.fromJson(response);
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _googleAuthService.signOut();
    await _tokenStorage.clearToken();
  }
}

