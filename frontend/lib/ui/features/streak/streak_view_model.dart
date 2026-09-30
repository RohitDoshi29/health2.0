import 'package:flutter/foundation.dart';
import '../../../data/models/streak_model.dart';
import '../../../data/repositories/streak_repository.dart';

class StreakViewModel extends ChangeNotifier {
  final StreakRepository _streakRepo;

  StreakViewModel({StreakRepository? streakRepository})
      : _streakRepo = streakRepository ?? StreakRepository();

  StreaksResponseModel? _data;
  StreaksResponseModel? get data => _data;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get currentStreak => _data?.currentStreak ?? 0;
  int get longestStreak => _data?.longestStreak ?? 0;
  int get todayScore => _data?.todayScore.score ?? 0;
  DailyScoreBreakdownModel? get breakdown => _data?.todayScore.breakdown;
  List<BadgeItemModel> get badges => _data?.badges ?? [];
  List<EarnedBadgeIdModel> get earnedBadges => _data?.earnedBadges ?? [];
  bool get streakActiveToday => _data?.streakActiveToday ?? false;

  Future<void> loadStreaks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _streakRepo.getStreaks();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
