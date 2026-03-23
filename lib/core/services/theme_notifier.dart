import 'package:flutter/material.dart';
import 'prefs_service.dart';

/// ChangeNotifier that holds the current ThemeMode and persists changes.
/// Wrap the app with ChangeNotifierProvider of ThemeNotifier so any widget
/// can call context.read and setMode to switch themes live.
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode;

  ThemeNotifier() : _mode = _fromPref(PrefsService.instance.themeMode);

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemePreference pref) async {
    await PrefsService.instance.setThemeMode(pref);
    _mode = _fromPref(pref);
    notifyListeners();
  }

  static ThemeMode _fromPref(ThemePreference pref) {
    switch (pref) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }
}
