import 'package:flutter/foundation.dart';
import '../../../data/models/weekly_model.dart';
import '../../../data/repositories/weekly_repository.dart';

class WeeklyViewModel extends ChangeNotifier {
  final WeeklyRepository _weeklyRepo;

  WeeklyViewModel({WeeklyRepository? weeklyRepository})
      : _weeklyRepo = weeklyRepository ?? WeeklyRepository();

  int _weekOffset = 0;
  int get weekOffset => _weekOffset;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WeeklyReportResponseModel? _report;
  WeeklyReportResponseModel? get report => _report;

  bool get canGoNext => _weekOffset < 0;

  DailyAveragesModel? get dailyAverages => _report?.dailyAverages;
  DaySummaryModel? get bestDay => _report?.bestDay;
  DaySummaryModel? get worstDay => _report?.worstDay;
  NutrientHitsModel? get nutrientHits => _report?.nutrientHits;
  WeightChangeModel? get weightChange => _report?.weightChange;
  PriorWeekComparisonModel? get priorComparison => _report?.priorWeekComparison;
  List<DailyBarPointModel> get dailyPoints => _report?.dailyPoints ?? [];

  Future<void> loadReport([int? offset]) async {
    if (offset != null) {
      _weekOffset = offset;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _weeklyRepo.getWeeklyReport(weekOffset: _weekOffset);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void previousWeek() {
    loadReport(_weekOffset - 1);
  }

  void nextWeek() {
    if (canGoNext) {
      loadReport(_weekOffset + 1);
    }
  }
}
