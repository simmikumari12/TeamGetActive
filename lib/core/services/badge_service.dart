import '../../data/repositories/badge_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/reflection_repository.dart';
import '../utils/streak_utils.dart';

/// Checks badge unlock conditions after each habit log and grants rewards.
/// Call [checkAll] after every log insert to keep badges current.
class BadgeService {
  BadgeService._();
  static final BadgeService instance = BadgeService._();

  /// Evaluates all badge conditions and unlocks any newly earned badges.
  /// Returns the list of badge codes that were newly unlocked this call.
  Future<List<String>> checkAll() async {
    final newly = <String>[];

    final badges = await BadgeRepository.instance.getAllBadges();
    final unlockedIds = await BadgeRepository.instance.getUnlockedBadgeIds();

    final logCount = await LogRepository.instance.totalCount();
    final habitCount = await HabitRepository.instance.count();
    final reflectionCount = await ReflectionRepository.instance.count();

    // Collect max streak and 7-day avg completion rate across all habits.
    // Both metrics are derived from the same 120-day log fetch to avoid
    // redundant DB queries.
    final habits = await HabitRepository.instance.getAll();
    int maxStreak = 0;
    double totalRate7 = 0;
    for (final h in habits) {
      final logs = await LogRepository.instance.getLogsInRange(
        h.id!,
        DateTime.now().subtract(const Duration(days: 120)),
        DateTime.now(),
      );
      final s = StreakUtils.computeStreak(logs);
      if (s > maxStreak) maxStreak = s;
      totalRate7 += StreakUtils.completionRate(logs, 7);
    }
    final avgRate7 = habits.isEmpty ? 0.0 : totalRate7 / habits.length;

    for (final badge in badges) {
      if (unlockedIds.contains(badge.id)) continue;

      final earned = _evaluate(
        badge.code,
        logCount: logCount,
        habitCount: habitCount,
        maxStreak: maxStreak,
        avgRate7: avgRate7,
        reflectionCount: reflectionCount,
      );
      if (earned) {
        await BadgeRepository.instance.unlock(badge.id!);
        newly.add(badge.code);
      }
    }
    return newly;
  }

  bool _evaluate(
    String code, {
    required int logCount,
    required int habitCount,
    required int maxStreak,
    required double avgRate7,
    required int reflectionCount,
  }) {
    switch (code) {
      case 'first_log':
        return logCount >= 1;
      case 'streak_3':
        return maxStreak >= 3;
      case 'streak_7':
        return maxStreak >= 7;
      case 'streak_14':
        return maxStreak >= 14;
      case 'streak_30':
        return maxStreak >= 30;
      case 'habits_5':
        return habitCount >= 5;
      case 'logs_50':
        return logCount >= 50;
      case 'logs_100':
        return logCount >= 100;
      case 'perfect_week':
        // All habits completed every day for the last 7 days
        return habitCount >= 1 && avgRate7 >= 1.0;
      case 'first_reflect':
        return reflectionCount >= 1;
      default:
        return false;
    }
  }
}
