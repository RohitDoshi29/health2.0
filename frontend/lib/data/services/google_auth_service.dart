import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  final String idToken;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? firebaseUid;

  const GoogleAuthResult({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.firebaseUid,
  });
}

class GoogleSignInConfigurationException implements Exception {
  final String message;
  final String packageName;
  final String sha1Fingerprint;

  const GoogleSignInConfigurationException({
    required this.message,
    this.packageName = 'com.heathify.heathify_app',
    this.sha1Fingerprint = 'B8:0D:4D:2E:77:3E:05:49:73:5F:1C:C3:35:EC:FE:D3:69:BD:E2:A1',
  });

  @override
  String toString() => message;
}

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth? _firebaseAuth;

  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId:
                  '684483169008-p2kn11kh6c9e5gfhng2r32j1c7asapmq.apps.googleusercontent.com',
              scopes: ['email', 'profile'],
            ),
        _firebaseAuth = firebaseAuth;

  FirebaseAuth? get _authInstance {
    if (_firebaseAuth != null) return _firebaseAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Future<GoogleAuthResult?> signIn() async {
    try {
      // 1. Trigger Google Sign In interactive flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow intentionally
        return null;
      }

      // 2. Obtain Google auth tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Authenticate with Firebase Auth if available
      String? firebaseUid;
      String? idToken = googleAuth.idToken;

      final auth = _authInstance;
      if (auth != null) {
        try {
          final AuthCredential credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
            accessToken: googleAuth.accessToken,
          );

          final UserCredential userCredential =
              await auth.signInWithCredential(credential);
          final User? firebaseUser = userCredential.user;
          if (firebaseUser != null) {
            firebaseUid = firebaseUser.uid;
            final token = await firebaseUser.getIdToken();
            if (token != null && token.isNotEmpty) {
              idToken = token;
            }
          }
        } catch (_) {
          // Fallback to Google ID token if Firebase Auth credential exchange is unavailable
        }
      }

      return GoogleAuthResult(
        idToken: idToken ?? googleAuth.idToken ?? 'token_${googleUser.id}',
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        firebaseUid: firebaseUid ?? googleUser.id,
      );
    } on PlatformException catch (pe) {
      if (pe.code == 'sign_in_canceled') {
        return null;
      }
      throw Exception('Google Sign-In error: ${pe.message ?? pe.code}');
    } on FirebaseAuthException catch (fe) {
      throw Exception(fe.message ?? 'Firebase authentication failed');
    } catch (e) {
      final errStr = e.toString();
      // Detect Google Play Services configuration / ApiException: 10 or 12500 error
      if (errStr.contains('ApiException') || errStr.contains('sign_in_failed')) {
        throw GoogleSignInConfigurationException(
          message:
              'Google Play Services requires registering the Android SHA-1 fingerprint in Firebase Console.\n\nError: $e',
        );
      }
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      final auth = _authInstance;
      if (auth != null) {
        await auth.signOut();
      }
    } catch (_) {}
  }
}
