import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_league/core/utils/streak_utils.dart';
import 'package:habit_mastery_league/data/models/habit_log.dart';

// ---------------------------------------------------------------------------
// Helpers — build logs relative to today so tests stay date-independent
// ---------------------------------------------------------------------------

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime _daysAgo(int n) => _today().subtract(Duration(days: n));

/// Monday of the current week (weekday == 1).
DateTime _thisMonday() {
  final t = _today();
  return t.subtract(Duration(days: t.weekday - 1));
}

/// A specific weekday (1=Mon … 7=Sun) of the current week.
DateTime _thisWeekDay(int weekday) =>
    _thisMonday().add(Duration(days: weekday - 1));

/// A specific weekday of n weeks ago.
DateTime _weekDayNWeeksAgo(int weekday, int weeksAgo) =>
    _thisMonday().subtract(Duration(days: 7 * weeksAgo - (weekday - 1)));

HabitLog _logOn(DateTime date, {int points = 10}) => HabitLog(
      habitId: 1,
      completedDate: date,
      pointsEarned: points,
    );

// ---------------------------------------------------------------------------
// computeStreak — daily habits
// ---------------------------------------------------------------------------

void main() {
  group('computeStreak (daily)', () {
    test('returns 0 for empty log list', () {
      expect(StreakUtils.computeStreak([]), 0);
    });

    test('returns 1 when only today is logged', () {
      final logs = [_logOn(_today())];
      expect(StreakUtils.computeStreak(logs), 1);
    });

    test('returns 1 when only yesterday is logged', () {
      final logs = [_logOn(_daysAgo(1))];
      expect(StreakUtils.computeStreak(logs), 1);
    });

    test('returns 2 for consecutive today + yesterday', () {
      final logs = [_logOn(_today()), _logOn(_daysAgo(1))];
      expect(StreakUtils.computeStreak(logs), 2);
    });

    test('returns 0 when last log is 2+ days ago (broken streak)', () {
      final logs = [_logOn(_daysAgo(2)), _logOn(_daysAgo(3))];
      expect(StreakUtils.computeStreak(logs), 0);
    });

    test('handles duplicate logs on same date without inflating streak', () {
      final logs = [
        _logOn(_today()),
        _logOn(_today()), // duplicate
        _logOn(_daysAgo(1)),
      ];
      expect(StreakUtils.computeStreak(logs), 2);
    });

    test('counts long unbroken streak correctly', () {
      final logs = List.generate(10, (i) => _logOn(_daysAgo(i)));
      expect(StreakUtils.computeStreak(logs), 10);
    });

    test('stops streak at gap even with older logs present', () {
      // Days 0,1,2 logged — then a gap at 3 — then old logs at 5,6
      final logs = [
        _logOn(_today()),
        _logOn(_daysAgo(1)),
        _logOn(_daysAgo(2)),
        _logOn(_daysAgo(5)),
        _logOn(_daysAgo(6)),
      ];
      expect(StreakUtils.computeStreak(logs), 3);
    });
  });

  // ---------------------------------------------------------------------------
  // computeWeeklyStreak
  // ---------------------------------------------------------------------------

  group('computeWeeklyStreak (weekly habits)', () {
    test('returns 0 for empty log list', () {
      expect(StreakUtils.computeWeeklyStreak([], 4), 0);
    });

    test('returns 0 when current and last week both below target', () {
      // Only 2 logs this week, target = 4
      final logs = [
        _logOn(_thisWeekDay(1)),
        _logOn(_thisWeekDay(2)),
      ];
      expect(StreakUtils.computeWeeklyStreak(logs, 4), 0);
    });

    test('returns 1 when this week meets target, nothing before', () {
      final logs = [
        _logOn(_thisWeekDay(1)),
        _logOn(_thisWeekDay(2)),
        _logOn(_thisWeekDay(3)),
        _logOn(_thisWeekDay(4)),
      ];
      expect(StreakUtils.computeWeeklyStreak(logs, 4), 1);
    });

    test('returns 1 when only last week meets target (current week in progress)', () {
      final logs = [
        _logOn(_weekDayNWeeksAgo(1, 1)),
        _logOn(_weekDayNWeeksAgo(2, 1)),
        _logOn(_weekDayNWeeksAgo(3, 1)),
        _logOn(_weekDayNWeeksAgo(4, 1)),
      ];
      expect(StreakUtils.computeWeeklyStreak(logs, 4), 1);
    });

    test('returns 2 when this week AND last week both meet target', () {
      final thisWeek = List.generate(
          4, (i) => _logOn(_thisWeekDay(i + 1)));
      final lastWeek = List.generate(
          4, (i) => _logOn(_weekDayNWeeksAgo(i + 1, 1)));
      expect(
          StreakUtils.computeWeeklyStreak([...thisWeek, ...lastWeek], 4), 2);
    });

    test('streak breaks if a middle week is below target', () {
      // This week: 4 ✓, last week: 2 ✗, 2 weeks ago: 4 ✓  → streak = 1
      final thisWeek = List.generate(4, (i) => _logOn(_thisWeekDay(i + 1)));
      final lastWeek = [
        _logOn(_weekDayNWeeksAgo(1, 1)),
        _logOn(_weekDayNWeeksAgo(2, 1)),
      ];
      final twoWeeksAgo =
          List.generate(4, (i) => _logOn(_weekDayNWeeksAgo(i + 1, 2)));
      expect(
          StreakUtils.computeWeeklyStreak(
              [...thisWeek, ...lastWeek, ...twoWeeksAgo], 4),
          1);
    });

    test('counts 3-week consecutive streak correctly', () {
      final w0 = List.generate(4, (i) => _logOn(_thisWeekDay(i + 1)));
      final w1 = List.generate(4, (i) => _logOn(_weekDayNWeeksAgo(i + 1, 1)));
      final w2 = List.generate(4, (i) => _logOn(_weekDayNWeeksAgo(i + 1, 2)));
      expect(StreakUtils.computeWeeklyStreak([...w0, ...w1, ...w2], 4), 3);
    });

    test('targetCount=1 works like an "once-a-week" habit', () {
      // Logged once last week, nothing this week → streak 1
      final logs = [_logOn(_weekDayNWeeksAgo(3, 1))];
      expect(StreakUtils.computeWeeklyStreak(logs, 1), 1);
    });

    test('extra logs beyond target do not inflate streak count', () {
      // Logged 7 days this week for a 4/7 target → still streak 1
      final logs =
          List.generate(7, (i) => _logOn(_thisWeekDay(i + 1)));
      expect(StreakUtils.computeWeeklyStreak(logs, 4), 1);
    });
  });

  // ---------------------------------------------------------------------------
  // currentWeekCount
  // ---------------------------------------------------------------------------

  group('currentWeekCount', () {
    test('returns 0 for empty logs', () {
      expect(StreakUtils.currentWeekCount([]), 0);
    });

    test('counts only logs from this Mon–Sun week', () {
      final logs = [
        _logOn(_thisWeekDay(1)),
        _logOn(_thisWeekDay(3)),
        _logOn(_weekDayNWeeksAgo(1, 1)), // last week — should NOT count
        _logOn(_daysAgo(30)),            // old — should NOT count
      ];
      expect(StreakUtils.currentWeekCount(logs), 2);
    });

    test('counts all 7 days if logged every day this week', () {
      final logs = List.generate(7, (i) => _logOn(_thisWeekDay(i + 1)));
      expect(StreakUtils.currentWeekCount(logs), 7);
    });
  });

  // ---------------------------------------------------------------------------
  // Missed-yesterday filtering logic
  // (mirrors the logic in DashboardScreen._loadData)
  // ---------------------------------------------------------------------------

  group('missed-yesterday filtering', () {
    // Pure function extracted from dashboard logic for testability
    Set<int> computeMissed({
      required List<Map<String, dynamic>> habits,
      required Set<int> completedYesterday,
      required DateTime today,
    }) {
      final todayStart = DateTime(today.year, today.month, today.day);
      return habits
          .where((h) =>
              h['frequencyType'] == 'daily' &&
              !completedYesterday.contains(h['id']) &&
              (h['createdAt'] as DateTime).isBefore(todayStart))
          .map((h) => h['id'] as int)
          .toSet();
    }

    final today = _today();

    test('habit created TODAY is NOT flagged as missed', () {
      // BUG CASE: habit with createdAt = today should be excluded
      final habits = [
        {'id': 1, 'frequencyType': 'daily', 'createdAt': today},
      ];
      final missed = computeMissed(
        habits: habits,
        completedYesterday: {},
        today: today,
      );
      expect(missed, isEmpty);
    });

    test('habit created 3 days ago and not done yesterday IS flagged', () {
      final habits = [
        {'id': 2, 'frequencyType': 'daily', 'createdAt': _daysAgo(3)},
      ];
      final missed = computeMissed(
        habits: habits,
        completedYesterday: {},
        today: today,
      );
      expect(missed, contains(2));
    });

    test('habit completed yesterday is NOT flagged', () {
      final habits = [
        {'id': 3, 'frequencyType': 'daily', 'createdAt': _daysAgo(5)},
      ];
      final missed = computeMissed(
        habits: habits,
        completedYesterday: {3},
        today: today,
      );
      expect(missed, isEmpty);
    });

    test('weekly habit is never flagged as missed', () {
      final habits = [
        {'id': 4, 'frequencyType': 'weekly', 'createdAt': _daysAgo(10)},
      ];
      final missed = computeMissed(
        habits: habits,
        completedYesterday: {},
        today: today,
      );
      expect(missed, isEmpty);
    });

    test('mix: only old unfinished daily habits are flagged', () {
      final habits = [
        {'id': 1, 'frequencyType': 'daily', 'createdAt': today},       // new → skip
        {'id': 2, 'frequencyType': 'daily', 'createdAt': _daysAgo(3)}, // old, not done → flag
        {'id': 3, 'frequencyType': 'daily', 'createdAt': _daysAgo(5)}, // old, done → skip
        {'id': 4, 'frequencyType': 'weekly', 'createdAt': _daysAgo(2)},// weekly → skip
      ];
      final missed = computeMissed(
        habits: habits,
        completedYesterday: {3},
        today: today,
      );
      expect(missed, equals({2}));
    });
  });
}
