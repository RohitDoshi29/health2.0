import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heathify_app/data/models/user_model.dart';
import 'package:heathify_app/data/repositories/auth_repository.dart';
import 'package:heathify_app/ui/core/widgets/google_sign_in_button.dart';
import 'package:heathify_app/ui/features/auth/auth_view_model.dart';
import 'package:heathify_app/ui/features/auth/login_view.dart';
import 'package:heathify_app/ui/features/auth/signup_view.dart';

class MockAuthRepository extends AuthRepository {
  bool googleSignInCalled = false;
  bool shouldSucceed = true;

  @override
  Future<AuthResponseModel?> signInWithGoogle() async {
    googleSignInCalled = true;
    if (!shouldSucceed) {
      throw Exception('Google Sign-In canceled by user');
    }
    return AuthResponseModel(
      accessToken: 'mock_jwt_token_for_google_user',
      tokenType: 'bearer',
      user: UserModel(
        id: 'user_google_1',
        name: 'Google Test User',
        email: 'googletest@example.com',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> isAuthenticated() async => false;
}

void main() {
  group('Google Sign-In Button and Auth Flow Tests', () {
    testWidgets('GoogleSignInButton renders text and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GoogleSignInButton(
                text: 'Continue with Google',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('LoginView displays Continue with Google button and triggers auth', (tester) async {
      final mockAuthRepo = MockAuthRepository();
      final authVm = AuthViewModel(authRepository: mockAuthRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVm,
            child: const LoginView(),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(mockAuthRepo.googleSignInCalled, isTrue);
      expect(authVm.isAuthenticated, isTrue);
      expect(authVm.currentUser?.email, 'googletest@example.com');
    });

    testWidgets('SignupView displays Sign up with Google button', (tester) async {
      final mockAuthRepo = MockAuthRepository();
      final authVm = AuthViewModel(authRepository: mockAuthRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVm,
            child: const SignupView(),
          ),
        ),
      );

      expect(find.text('Sign up with Google'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
    });
  });
}
