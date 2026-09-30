import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/sync_manager.dart';
import 'firebase_options.dart';
import 'ui/features/auth/auth_view_model.dart';
import 'ui/features/auth/login_view.dart';
import 'ui/features/home/home_view.dart';
import 'ui/features/home/home_view_model.dart';
import 'ui/features/onboarding/onboarding_view.dart';
import 'ui/features/onboarding/onboarding_view_model.dart';
import 'ui/features/scan/scan_view_model.dart';
import 'ui/features/water/water_view_model.dart';
import 'ui/features/weight/weight_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }
  runApp(const HeathifyApp());
}

class HeathifyApp extends StatelessWidget {
  const HeathifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncManager()..init()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ScanViewModel()),
        ChangeNotifierProvider(create: (_) => WaterViewModel()..loadTodaySummary()),
        ChangeNotifierProvider(create: (_) => WeightViewModel()),
      ],
      child: MaterialApp(
        title: 'Heathify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _RootScreen(),
      ),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    if (authVm.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.spa_rounded, size: 64, color: AppTheme.primaryGreen),
              SizedBox(height: 16),
              Text(
                'Heathify',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (authVm.isAuthenticated) {
      if (authVm.currentUser != null && !authVm.currentUser!.onboardingCompleted) {
        return const OnboardingView();
      }
      return const HomeView();
    }

    return const LoginView();
  }
}
