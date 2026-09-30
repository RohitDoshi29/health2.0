import 'package:flutter/foundation.dart';
import '../../../data/models/weight_model.dart';
import '../../../data/repositories/weight_repository.dart';

class WeightViewModel extends ChangeNotifier {
  final WeightRepository _weightRepo;

  WeightViewModel({WeightRepository? weightRepository})
      : _weightRepo = weightRepository ?? WeightRepository();

  int _selectedDays = 30;
  int get selectedDays => _selectedDays;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WeightHistoryResponseModel? _history;
  WeightHistoryResponseModel? get history => _history;

  double? get currentWeight => _history?.currentWeight;
  double? get sevenDayDelta => _history?.change7dKg;
  double? get totalDelta => _history?.changeTotalKg;

  void setSelectedDays(int days) {
    _selectedDays = days;
    notifyListeners();
  }

  Future<void> loadHistory([int? days]) async {
    if (days != null) {
      _selectedDays = days;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _weightRepo.getWeightHistory(days: _selectedDays);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logWeight(double weightKg, {String? note, DateTime? loggedAt}) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _weightRepo.logWeight(weightKg, note: note, loggedAt: loggedAt);
      await loadHistory();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWeight(String id) async {
    try {
      await _weightRepo.deleteWeight(id);
      await loadHistory();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
