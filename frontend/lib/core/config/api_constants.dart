class ApiConstants {
  // Configurable via --dart-define=API_URL=http://... or defaults to live Render backend
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    return 'https://heathify-api.onrender.com';
  }

  static const String signup = '/api/v1/auth/signup';
  static const String login = '/api/v1/auth/login';
  static const String me = '/api/v1/auth/me';
  static const String analyze = '/api/v1/analysis/analyze';
  static const String meals = '/api/v1/meals';
  static const String foods = '/api/v1/nutrition/foods';
  static const String goals = '/api/v1/users/me/goals';
  static const String dailyAnalytics = '/api/v1/analytics/daily';
  static const String trendsAnalytics = '/api/v1/analytics/trends';
  static const String barcode = '/api/v1/nutrition/barcode';
  static const String favorites = '/api/v1/favorites';
  static const String googleAuth = '/api/v1/auth/google';
  static const String firebaseAuth = '/api/v1/auth/firebase';
  static const String water = '/api/v1/water';
  static const String waterToday = '/api/v1/water/today';
  static const String waterHistory = '/api/v1/water/history';
  static const String waterGoal = '/api/v1/water/goal';
  static const String profile = '/api/v1/users/me/profile';
  static const String profilePreview = '/api/v1/users/me/profile/preview';
  static const String weight = '/api/v1/weight';
  static const String weightHistory = '/api/v1/weight/history';
  static const String streaks = '/api/v1/analytics/streaks';
  static const String weeklyReport = '/api/v1/analytics/weekly';
  static const String recentFoods = '/api/v1/meals/recent-foods';
  static String relogMeal(String id) => '/api/v1/meals/$id/relog';
  static const String portions = '/api/v1/nutrition/portions';
  static String foodPortions(String id) => '/api/v1/nutrition/foods/$id/portions';
}


