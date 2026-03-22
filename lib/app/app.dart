import 'package:flutter/material.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget of Habit Mastery League.
/// Configures theming, routing, and app-wide MaterialApp settings.
class HabitMasteryApp extends StatelessWidget {
  const HabitMasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Mastery League',
      debugShowCheckedModeBanner: false,

      // Theme — follows system setting by default; overridable via settings screen
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Navigation
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
