import '../../data/models/habit_log.dart';
import '../constants/app_constants.dart';

/// Pure functions for streak and XP calculations.
/// No database calls — pass in logs from a repository.
class StreakUtils {
  StreakUtils._();

  /// Counts consecutive completed days ending on today or yesterday.
  /// Returns 0 if the most recent log is older than yesterday.
  static int computeStreak(List<HabitLog> logs) {
    if (logs.isEmpty) return 0;

    final dates = logs
        .map((l) => _dateOnly(l.completedDate))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (dates.first != today && dates.first != yesterday) return 0;

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final expected = dates[i - 1].subtract(const Duration(days: 1));
      if (dates[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Sums all points_earned across all logs.
  static int computeTotalXp(List<HabitLog> logs) =>
      logs.fold(0, (sum, l) => sum + l.pointsEarned);

  /// Level 1 starts at 0 XP; each level requires xpPerLevel XP.
  static int computeLevel(int totalXp) =>
      (totalXp ~/ AppConstants.xpPerLevel) + 1;

  /// XP earned within the current level (progress bar value).
  static int xpIntoCurrentLevel(int totalXp) =>
      totalXp % AppConstants.xpPerLevel;

  /// XP still needed to reach the next level.
  static int xpToNextLevel(int totalXp) =>
      AppConstants.xpPerLevel - xpIntoCurrentLevel(totalXp);

  /// Completion rate over the last [days] days (0.0 – 1.0).
  static double completionRate(List<HabitLog> logs, int days) {
    if (days <= 0) return 0.0;
    final today = _dateOnly(DateTime.now());
    final completedDates = logs.map((l) => _dateOnly(l.completedDate)).toSet();
    int completed = 0;
    for (int i = 0; i < days; i++) {
      if (completedDates.contains(today.subtract(Duration(days: i)))) {
        completed++;
      }
    }
    return completed / days;
  }

  /// Unique completed dates — used by the heatmap widget.
  static Set<DateTime> completedDates(List<HabitLog> logs) =>
      logs.map((l) => _dateOnly(l.completedDate)).toSet();

  /// For weekly habits: counts consecutive Mon–Sun weeks ending this or last
  /// week where the habit was logged at least [targetCount] times.
  static int computeWeeklyStreak(List<HabitLog> logs, int targetCount) {
    if (logs.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    // Monday of current week
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));

    // Build weekStart → completion count
    final Map<DateTime, int> weekCounts = {};
    for (final log in logs) {
      final d = _dateOnly(log.completedDate);
      final ws = d.subtract(Duration(days: d.weekday - 1));
      weekCounts[ws] = (weekCounts[ws] ?? 0) + 1;
    }

    // Streak must include this week or last week
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final DateTime cursor;
    if ((weekCounts[thisWeekStart] ?? 0) >= targetCount) {
      cursor = thisWeekStart;
    } else if ((weekCounts[lastWeekStart] ?? 0) >= targetCount) {
      cursor = lastWeekStart;
    } else {
      return 0;
    }

    int streak = 1;
    DateTime prev = cursor.subtract(const Duration(days: 7));
    while ((weekCounts[prev] ?? 0) >= targetCount) {
      streak++;
      prev = prev.subtract(const Duration(days: 7));
    }
    return streak;
  }

  /// Count of logs in the current Mon–Sun week.
  static int currentWeekCount(List<HabitLog> logs) {
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return logs
        .where((l) {
          final d = _dateOnly(l.completedDate);
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        })
        .length;
  }

  /// Points for one completion, applying difficulty and streak bonus.
  static int calculatePoints(String difficulty, int currentStreak) {
    final base = AppConstants.basePointsPerCompletion;
    final mult = AppConstants.difficultyMultipliers[difficulty] ?? 1.0;
    final bonus = currentStreak >= AppConstants.streakBonusThreshold
        ? AppConstants.streakBonusMultiplier
        : 1.0;
    return (base * mult * bonus).toInt();
  }

  /// Strips time from a DateTime, returning midnight on that day.
  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
