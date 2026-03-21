/// Global constants for Habit Mastery League.
/// Centralizes strings, keys, durations, and game rules.
class AppConstants {
  AppConstants._();

  // --- App info ---
  static const String appName = 'Habit Mastery League';
  static const String appVersion = '1.0.0';

  // --- SharedPreferences keys ---
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserName = 'user_name';
  static const String keyBuddyPersonality = 'buddy_personality';
  static const String keyEncouragementStyle = 'encouragement_style';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyLastBuddyMessage = 'last_buddy_message';
  static const String keyLastBuddyDate = 'last_buddy_date';

  // --- Gamification rules ---
  static const int basePointsPerCompletion = 10;
  // Bonus multiplier applied when streak >= streakBonusThreshold
  static const int streakBonusThreshold = 7;
  static const double streakBonusMultiplier = 2.0;
  static const int maxStreakShields = 3;
  // XP needed to level up each time
  static const int xpPerLevel = 500;

  // Day counts that trigger streak milestone badges
  static const List<int> streakMilestones = [3, 7, 14, 30, 60, 100];

  // Points multiplied by this per difficulty level
  static const Map<String, double> difficultyMultipliers = {
    'easy': 1.0,
    'medium': 1.5,
    'hard': 2.0,
  };

  // --- Habit categories ---
  static const List<String> habitCategories = [
    'Health',
    'Fitness',
    'Learning',
    'Mindfulness',
    'Productivity',
    'Social',
    'Finance',
    'Creativity',
    'Other',
  ];

  // --- AI Buddy personality options ---
  static const List<String> buddyPersonalities = [
    'Encouraging Coach',
    'Strict Trainer',
    'Calm Mentor',
    'Playful Friend',
  ];

  // --- Database ---
  static const String dbName = 'habit_mastery.db';
  static const int dbVersion = 1;

  // --- Animation durations ---
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration fadeInDuration = Duration(milliseconds: 600);
  static const Duration slideTransitionDuration = Duration(milliseconds: 300);
}
