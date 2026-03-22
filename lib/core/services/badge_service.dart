import '../../data/repositories/badge_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/log_repository.dart';
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

    // Collect max streak across all habits for streak-based badges
    final habits = await HabitRepository.instance.getAll();
    int maxStreak = 0;
    for (final h in habits) {
      final logs = await LogRepository.instance.getLogsInRange(
        h.id!,
        DateTime.now().subtract(const Duration(days: 120)),
        DateTime.now(),
      );
      final s = StreakUtils.computeStreak(logs);
      if (s > maxStreak) maxStreak = s;
    }

    for (final badge in badges) {
      if (unlockedIds.contains(badge.id)) continue;

      final earned = _evaluate(badge.code, logCount, habitCount, maxStreak);
      if (earned) {
        await BadgeRepository.instance.unlock(badge.id!);
        newly.add(badge.code);
      }
    }
    return newly;
  }

  bool _evaluate(String code, int logCount, int habitCount, int maxStreak) {
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
      default:
        return false;
    }
  }
}
