import 'package:flutter/foundation.dart';
import '../../core/config/api_constants.dart';
import '../models/meal_model.dart';
import 'api_client.dart';
import 'local_storage_service.dart';

class SyncManager extends ChangeNotifier {
  final LocalStorageService _storage;
  final ApiClient _apiClient;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncManager({
    LocalStorageService? storage,
    ApiClient? apiClient,
  })  : _storage = storage ?? LocalStorageService(),
        _apiClient = apiClient ?? ApiClient();

  Future<void> init() async {
    _lastSyncTime = await _storage.getLastSyncTimestamp();
    await refreshPendingCount();
  }

  Future<void> refreshPendingCount() async {
    final actions = await _storage.getPendingSyncActions();
    _pendingCount = actions.length;
    notifyListeners();
  }

  Future<int> triggerSync() => syncPendingActions();

  Future<int> syncPendingActions() async {
    if (_isSyncing) return 0;

    _isSyncing = true;
    notifyListeners();

    int syncedCount = 0;
    try {
      final actions = await _storage.getPendingSyncActions();
      final cachedMeals = await _storage.getCachedMeals();

      for (final action in actions) {
        final actionId = action['id'] as String;
        final actionType = action['action'] as String;

        try {
          if (actionType == 'CREATE') {
            final payload = action['payload'] as Map<String, dynamic>;
            final tempLocalId = action['temp_meal_id'] as String?;

            final response = await _apiClient.post(ApiConstants.meals, payload);
            final realMeal = MealModel.fromJson(response);

            // Reconcile local cache: replace temp local meal with the real saved meal
            if (tempLocalId != null) {
              final idx = cachedMeals.indexWhere((m) => m.id == tempLocalId);
              if (idx != -1) {
                cachedMeals[idx] = realMeal;
              } else if (!cachedMeals.any((m) => m.id == realMeal.id)) {
                cachedMeals.insert(0, realMeal);
              }
            } else if (!cachedMeals.any((m) => m.id == realMeal.id)) {
              cachedMeals.insert(0, realMeal);
            }

            await _storage.removePendingSyncAction(actionId);
            syncedCount++;
          } else if (actionType == 'DELETE') {
            final mealId = action['meal_id'] as String;
            try {
              await _apiClient.delete('${ApiConstants.meals}/$mealId');
            } catch (_) {
              // If already 404 on server, consider it synced
            }
            cachedMeals.removeWhere((m) => m.id == mealId);
            await _storage.removePendingSyncAction(actionId);
            syncedCount++;
          }
        } catch (e) {
          // If network error occurred, stop processing further items and keep in queue
          break;
        }
      }

      await _storage.saveCachedMeals(cachedMeals);
      final now = DateTime.now();
      _lastSyncTime = now;
      await _storage.setLastSyncTimestamp(now);
    } finally {
      _isSyncing = false;
      await refreshPendingCount();
    }

    return syncedCount;
  }
}

