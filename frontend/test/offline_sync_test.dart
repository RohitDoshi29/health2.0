import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/analysis_model.dart';
import 'package:heathify_app/data/models/meal_model.dart';
import 'package:heathify_app/data/repositories/meal_repository.dart';
import 'package:heathify_app/data/services/api_client.dart';
import 'package:heathify_app/data/services/local_storage_service.dart';
import 'package:heathify_app/data/services/sync_manager.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageService Tests', () {
    test('saves and retrieves cached meals', () async {
      final storage = LocalStorageService();
      final now = DateTime.now();

      final meals = [
        MealModel(
          id: 'meal-1',
          userId: 'user-1',
          mealType: 'lunch',
          totalCalories: 450,
          totalProtein: 30,
          totalCarbohydrates: 50,
          totalFat: 12,
          totalFiber: 4,
          createdAt: now,
          updatedAt: now,
          items: [],
        ),
      ];

      await storage.saveCachedMeals(meals);
      final retrieved = await storage.getCachedMeals();

      expect(retrieved.length, 1);
      expect(retrieved.first.id, 'meal-1');
      expect(retrieved.first.totalCalories, 450.0);
    });

    test('enqueues and removes pending sync actions', () async {
      final storage = LocalStorageService();

      final action = {
        'id': 'action-1',
        'action': 'CREATE',
        'temp_meal_id': 'local_123',
        'payload': {'meal_type': 'dinner'},
      };

      await storage.addPendingSyncAction(action);
      var pending = await storage.getPendingSyncActions();
      expect(pending.length, 1);
      expect(pending.first['id'], 'action-1');

      await storage.removePendingSyncAction('action-1');
      pending = await storage.getPendingSyncActions();
      expect(pending.isEmpty, isTrue);
    });
  });

  group('MealRepository Offline-First Fallback Tests', () {
    test('saveMeal falls back to local cache when offline', () async {
      final storage = LocalStorageService();
      final syncManager = SyncManager(storage: storage);
      await syncManager.init();

      // Repository with offline client that fails immediately without timeout
      final offlineClient = ApiClient(
        client: MockClient((_) async => throw Exception('Network unreachable (offline)')),
      );
      final repo = MealRepository(
        apiClient: offlineClient,
        storage: storage,
        syncManager: syncManager,
      );

      final items = [
        MealItemAnalysisModel(
          name: 'Avocado Toast',
          quantity: 100,
          unit: 'g',
          estimatedCalories: 250,
          protein: 6,
          carbohydrates: 25,
          fat: 15,
          fiber: 7,
        ),
      ];

      final saved = await repo.saveMeal(mealType: 'breakfast', items: items);
      expect(saved.id.startsWith('local_'), isTrue);
      expect(saved.totalCalories, 250.0);

      // Verify cached locally
      final cached = await storage.getCachedMeals();
      expect(cached.length, 1);
      expect(cached.first.mealType, 'breakfast');

      // Verify action queued in outbox
      final pending = await storage.getPendingSyncActions();
      expect(pending.length, 1);
      expect(pending.first['action'], 'CREATE');
      expect(syncManager.pendingCount, 1);
    });
  });
}

