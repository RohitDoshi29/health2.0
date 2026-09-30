import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/weight_model.dart';
import 'package:heathify_app/ui/features/weight/weight_view_model.dart';

void main() {
  group('Weight Models Tests', () {
    test('WeightLogModel serialization & deserialization', () {
      final json = {
        'id': 'log-123',
        'user_id': 'user-456',
        'weight_kg': 72.5,
        'logged_at': '2026-03-30T10:00:00Z',
        'note': 'Morning weigh-in',
        'created_at': '2026-03-30T10:00:00Z',
      };

      final log = WeightLogModel.fromJson(json);
      expect(log.id, 'log-123');
      expect(log.userId, 'user-456');
      expect(log.weightKg, 72.5);
      expect(log.loggedAt, DateTime.parse('2026-03-30T10:00:00Z'));
      expect(log.note, 'Morning weigh-in');

      final outJson = log.toJson();
      expect(outJson['weight_kg'], 72.5);
      expect(outJson['note'], 'Morning weigh-in');
    });

    test('WeightHistoryPointModel deserialization', () {
      final json = {
        'date': '2026-03-30',
        'weight_kg': 71.8,
        'calories_consumed': 2150.0,
      };

      final point = WeightHistoryPointModel.fromJson(json);
      expect(point.date, '2026-03-30');
      expect(point.weightKg, 71.8);
      expect(point.caloriesConsumed, 2150.0);
    });

    test('WeightHistoryResponseModel deserialization with deltas', () {
      final json = {
        'current_weight': 70.5,
        'start_weight': 73.0,
        'change_7d_kg': -0.8,
        'change_total_kg': -2.5,
        'days': 30,
        'points': [
          {
            'date': '2026-03-23',
            'weight_kg': 71.3,
            'calories_consumed': 1950.0,
          },
          {
            'date': '2026-03-30',
            'weight_kg': 70.5,
            'calories_consumed': 2050.0,
          }
        ],
      };

      final response = WeightHistoryResponseModel.fromJson(json);
      expect(response.currentWeight, 70.5);
      expect(response.startWeight, 73.0);
      expect(response.change7dKg, -0.8);
      expect(response.changeTotalKg, -2.5);
      expect(response.days, 30);
      expect(response.points.length, 2);
      expect(response.points.first.weightKg, 71.3);
      expect(response.points.last.weightKg, 70.5);
    });
  });

  group('WeightViewModel State Tests', () {
    test('Initial state and range selection', () {
      final vm = WeightViewModel();
      expect(vm.selectedDays, 30);
      expect(vm.history, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.currentWeight, isNull);
      expect(vm.sevenDayDelta, isNull);
      expect(vm.totalDelta, isNull);

      vm.setSelectedDays(7);
      expect(vm.selectedDays, 7);

      vm.setSelectedDays(90);
      expect(vm.selectedDays, 90);
    });
  });
}
