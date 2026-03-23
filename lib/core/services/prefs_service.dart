import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Singleton wrapper around SharedPreferences.
/// Call PrefsService.instance.init() before use (done in main.dart).
class PrefsService {
  PrefsService._();

  static final PrefsService instance = PrefsService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'PrefsService.init() must be called before use.');
    return _prefs!;
  }

  // --- Theme ---

  ThemePreference get themeMode {
    final val = _p.getString(AppConstants.keyThemeMode) ?? 'system';
    return ThemePreference.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ThemePreference.system,
    );
  }

  Future<void> setThemeMode(ThemePreference mode) =>
      _p.setString(AppConstants.keyThemeMode, mode.name);

  // --- Onboarding ---

  bool get onboardingDone => _p.getBool(AppConstants.keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone() =>
      _p.setBool(AppConstants.keyOnboardingDone, true);

  // --- User profile ---

  String get userName => _p.getString(AppConstants.keyUserName) ?? 'Habit Hero';

  Future<void> setUserName(String name) =>
      _p.setString(AppConstants.keyUserName, name.trim());

  String get buddyPersonality =>
      _p.getString(AppConstants.keyBuddyPersonality) ??
      AppConstants.buddyPersonalities.first;

  Future<void> setBuddyPersonality(String personality) =>
      _p.setString(AppConstants.keyBuddyPersonality, personality);

  // --- Notifications (placeholder for future implementation) ---

  bool get notificationsEnabled =>
      _p.getBool(AppConstants.keyNotificationsEnabled) ?? false;

  Future<void> setNotificationsEnabled(bool enabled) =>
      _p.setBool(AppConstants.keyNotificationsEnabled, enabled);

  // --- AI Buddy message cache ---
  // The buddy message is regenerated once per day and cached here.

  String? get lastBuddyMessage => _p.getString(AppConstants.keyLastBuddyMessage);
  String? get lastBuddyDate => _p.getString(AppConstants.keyLastBuddyDate);
  String? get lastMicroGoal => _p.getString(AppConstants.keyLastMicroGoal);

  /// Caches both the pep message and the micro-goal for today.
  Future<void> cacheMessages(String message, String microGoal) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _p.setString(AppConstants.keyLastBuddyMessage, message);
    await _p.setString(AppConstants.keyLastMicroGoal, microGoal);
    await _p.setString(AppConstants.keyLastBuddyDate, today);
  }

  // --- Claude API key ---

  String get claudeApiKey =>
      _p.getString(AppConstants.keyClaudeApiKey) ?? '';

  Future<void> setClaudeApiKey(String key) =>
      _p.setString(AppConstants.keyClaudeApiKey, key.trim());

  /// Returns true if the cached buddy messages were generated today.
  bool get isBuddyMessageFresh {
    final cached = lastBuddyDate;
    if (cached == null) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return cached == today;
  }
}

/// Represents the user's chosen theme preference.
enum ThemePreference { light, dark, system }
