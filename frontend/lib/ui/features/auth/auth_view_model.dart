import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        // Immediately authenticate with existing credentials so user is not stuck on loading screen
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        // Refresh user profile in background without blocking app display
        try {
          _currentUser = await _authRepository.getMe().timeout(const Duration(seconds: 8));
          notifyListeners();
        } catch (e) {
          // If token was rejected as unauthorized, log out cleanly
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('401') || errStr.contains('unauthorized')) {
            await logout();
          }
        }
        return;
      } else {
        _isAuthenticated = false;
      }
    } catch (_) {
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _authRepository.login(email: email, password: password);
      _currentUser = authResponse.user;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _authRepository.signup(
        name: name,
        email: email,
        password: password,
      );
      _currentUser = authResponse.user;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _authRepository.signInWithGoogle();
      if (authResponse == null) {
        // User cancelled flow
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _currentUser = authResponse.user;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogleDirect({required String email, String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResponse = await _authRepository.signInWithGoogleDirect(
        email: email,
        name: name,
      );
      _currentUser = authResponse.user;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

