import 'package:flutter/foundation.dart';
import '../../../data/models/water_model.dart';
import '../../../data/repositories/water_repository.dart';

class WaterViewModel extends ChangeNotifier {
  final WaterRepository _repository;

  DailyWaterSummaryModel _summary = DailyWaterSummaryModel.initial();
  DailyWaterSummaryModel get summary => _summary;

  List<WaterHistoryDayModel> _history = [];
  List<WaterHistoryDayModel> get history => _history;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLogging = false;
  bool get isLogging => _isLogging;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WaterViewModel({WaterRepository? repository})
      : _repository = repository ?? WaterRepository();

  Future<void> loadTodaySummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _repository.getTodaySummary();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> quickLog(double amountMl) async {
    _isLogging = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _repository.logWater(amountMl);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLogging = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLog(String logId) async {
    try {
      final success = await _repository.deleteLog(logId);
      if (success) {
        await loadTodaySummary();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGoal(double targetMl) async {
    try {
      await _repository.updateWaterGoal(targetMl);
      await loadTodaySummary();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadHistory({int days = 7}) async {
    try {
      _history = await _repository.getHistory(days: days);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}

