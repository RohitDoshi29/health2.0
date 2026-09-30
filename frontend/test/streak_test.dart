import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/data/models/streak_model.dart';
import 'package:heathify_app/ui/features/streak/streak_view_model.dart';

void main() {
  group('Streak & Score Models Tests', () {
    test('ScoreBreakdownItemModel deserialization & serialization', () {
      final json = {
        'points': 40.0,
        'max_points': 40.0,
        'achieved': true,
        'value': 2050.0,
        'target': 2000.0,
        'description': 'Within ±10% of 2000 kcal',
      };

      final item = ScoreBreakdownItemModel.fromJson(json);
      expect(item.points, 40.0);
      expect(item.maxPoints, 40.0);
      expect(item.achieved, isTrue);
      expect(item.value, 2050.0);
      expect(item.target, 2000.0);
      expect(item.description, 'Within ±10% of 2000 kcal');

      final out = item.toJson();
      expect(out['points'], 40.0);
      expect(out['achieved'], isTrue);
    });

    test('DailyScoreModel deserialization with 4 breakdown categories', () {
      final json = {
        'date': '2026-03-30',
        'score': 85,
        'breakdown': {
          'calories': {
            'points': 40.0,
            'max_points': 40.0,
            'achieved': true,
            'value': 2000.0,
            'target': 2000.0,
            'description': 'Within ±10%',
          },
          'protein': {
            'points': 30.0,
            'max_points': 30.0,
            'achieved': true,
            'value': 110.0,
            'target': 120.0,
            'description': '>= 90%',
          },
          'fiber': {
            'points': 15.0,
            'max_points': 15.0,
            'achieved': true,
            'value': 25.0,
            'target': 30.0,
            'description': '>= 80%',
          },
          'water': {
            'points': 0.0,
            'max_points': 15.0,
            'achieved': false,
            'value': 1500.0,
            'target': 2500.0,
            'description': '>= 100%',
          },
        },
      };

      final score = DailyScoreModel.fromJson(json);
      expect(score.date, '2026-03-30');
      expect(score.score, 85);
      expect(score.breakdown.calories.achieved, isTrue);
      expect(score.breakdown.protein.achieved, isTrue);
      expect(score.breakdown.fiber.achieved, isTrue);
      expect(score.breakdown.water.achieved, isFalse);
    });

    test('StreaksResponseModel deserialization with badges catalog', () {
      final json = {
        'current_streak': 5,
        'longest_streak': 12,
        'streak_active_today': true,
        'today_score': {
          'date': '2026-03-30',
          'score': 70,
          'breakdown': {
            'calories': {
              'points': 40.0,
              'max_points': 40.0,
              'achieved': true,
              'value': 1950.0,
              'target': 2000.0,
              'description': 'cal',
            },
            'protein': {
              'points': 30.0,
              'max_points': 30.0,
              'achieved': true,
              'value': 115.0,
              'target': 120.0,
              'description': 'prot',
            },
            'fiber': {
              'points': 0.0,
              'max_points': 15.0,
              'achieved': false,
              'value': 15.0,
              'target': 30.0,
              'description': 'fib',
            },
            'water': {
              'points': 0.0,
              'max_points': 15.0,
              'achieved': false,
              'value': 1000.0,
              'target': 2500.0,
              'description': 'wat',
            },
          },
        },
        'earned_badges': [
          {'id': 'streak_3', 'earned_at': '2026-03-28'},
          {'id': 'hit_protein_today', 'earned_at': '2026-03-30'},
        ],
        'badges': [
          {
            'id': 'streak_3',
            'name': '3-Day Streak',
            'description': 'Hit 60+ for 3 consecutive days',
            'icon': 'local_fire_department',
            'unlocked': true,
            'earned_at': '2026-03-28',
          },
          {
            'id': 'streak_7',
            'name': '7-Day Streak',
            'description': 'Maintained for 7 days',
            'icon': 'military_tech',
            'unlocked': false,
            'earned_at': null,
          },
        ],
      };

      final res = StreaksResponseModel.fromJson(json);
      expect(res.currentStreak, 5);
      expect(res.longestStreak, 12);
      expect(res.streakActiveToday, isTrue);
      expect(res.todayScore.score, 70);
      expect(res.earnedBadges.length, 2);
      expect(res.earnedBadges.first.id, 'streak_3');
      expect(res.badges.length, 2);
      expect(res.badges.first.unlocked, isTrue);
      expect(res.badges.last.unlocked, isFalse);
    });
  });

  group('StreakViewModel State Tests', () {
    test('Initial state getters', () {
      final vm = StreakViewModel();
      expect(vm.currentStreak, 0);
      expect(vm.longestStreak, 0);
      expect(vm.todayScore, 0);
      expect(vm.breakdown, isNull);
      expect(vm.badges, isEmpty);
      expect(vm.earnedBadges, isEmpty);
      expect(vm.streakActiveToday, isFalse);
      expect(vm.isLoading, isFalse);
    });
  });
}
