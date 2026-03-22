import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../constants/app_constants.dart';
import '../services/prefs_service.dart';
import '../utils/streak_utils.dart';

/// Rule-based buddy message generator. No external API calls.
/// Generates one message per day and caches it in SharedPreferences.
class BuddyService {
  BuddyService._();
  static final BuddyService instance = BuddyService._();

  /// Returns today's buddy message. Uses cache if already generated today.
  Future<String> getMessage() async {
    if (PrefsService.instance.isBuddyMessageFresh) {
      return PrefsService.instance.lastBuddyMessage ?? _fallback();
    }
    final message = await _generate();
    await PrefsService.instance.cacheBuddyMessage(message);
    return message;
  }

  Future<String> _generate() async {
    final name = PrefsService.instance.userName;
    final personality = PrefsService.instance.buddyPersonality;
    final habits = await HabitRepository.instance.getAll();
    if (habits.isEmpty) return _welcomeMessage(name, personality);

    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    int maxStreak = 0;
    double totalRate = 0;
    for (final h in habits) {
      final logs = await LogRepository.instance.getLogsInRange(h.id!, from, now);
      final s = StreakUtils.computeStreak(logs);
      if (s > maxStreak) maxStreak = s;
      totalRate += StreakUtils.completionRate(logs, 7);
    }
    final avgRate = habits.isEmpty ? 0.0 : totalRate / habits.length;

    return _buildMessage(name, personality, maxStreak, avgRate, habits.length);
  }

  String _buildMessage(
    String name,
    String personality,
    int maxStreak,
    double avgRate,
    int habitCount,
  ) {
    final pct = (avgRate * 100).round();

    if (personality == AppConstants.buddyPersonalities[1]) {
      // Strict Trainer
      if (maxStreak == 0) return '$name, zero streak is unacceptable. Get moving — now.';
      if (pct < 50) return 'Only $pct%? $name, you\'re capable of more. No excuses.';
      if (maxStreak >= 7) return '$maxStreak days straight, $name. Acceptable. Keep the pace.';
      return '$name, $pct% this week. Push harder tomorrow.';
    }

    if (personality == AppConstants.buddyPersonalities[2]) {
      // Calm Mentor
      if (maxStreak == 0) return 'Every journey begins with a single step, $name. Begin today.';
      if (pct < 50) return 'Progress, not perfection, $name. Each small effort shapes who you become.';
      if (maxStreak >= 7) return 'A $maxStreak-day streak speaks to your commitment, $name. Stay present.';
      return 'You\'re doing meaningful work, $name. $pct% completion is a real foundation.';
    }

    if (personality == AppConstants.buddyPersonalities[3]) {
      // Playful Friend
      if (maxStreak == 0) return 'Hey $name! 👀 Your habits miss you — time to show up!';
      if (pct < 50) return '$pct%? $name you\'ve totally got this, let\'s gooo!';
      if (maxStreak >= 7) return 'SEVEN days?! $name you\'re literally unstoppable 🔥';
      return 'Look at you, $name! $pct% this week, keeping it real 💪';
    }

    // Default: Encouraging Coach
    if (maxStreak == 0) return 'Ready to start, $name? Every streak begins with today\'s first check-in!';
    if (pct < 50) return 'You\'re at $pct% this week, $name. Small wins add up — keep going!';
    if (maxStreak >= 7) return 'Incredible, $name! A $maxStreak-day streak shows real dedication. You\'re building something lasting.';
    return 'Great work, $name! $pct% completion this week across $habitCount habits. You\'re on track!';
  }

  String _welcomeMessage(String name, String personality) {
    if (personality == AppConstants.buddyPersonalities[1]) {
      return '$name, no habits created yet. Fix that immediately.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'Welcome, $name. Add your first habit and let the journey unfold.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return 'Hey $name! Add your first habit and let\'s get this party started 🎉';
    }
    return 'Welcome, $name! Add your first habit to get started on your journey.';
  }

  String _fallback() => 'Keep going — every day counts!';
}
