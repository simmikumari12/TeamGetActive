import 'package:flutter/material.dart';
import '../data/models/habit.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/dashboard/screens/main_screen.dart';
import '../features/habits/screens/habits_screen.dart';
import '../features/habits/screens/add_habit_screen.dart';
import '../features/habits/screens/add_edit_habit_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/insights/screens/insights_screen.dart';
import '../features/rewards/screens/rewards_screen.dart';
import '../features/settings/screens/settings_screen.dart';

/// Central route registry for Habit Mastery League.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String habits = '/habits';
  static const String addHabit = '/habits/add';
  static const String editHabit = '/habits/edit';
  static const String progress = '/progress';
  static const String insights = '/insights';
  static const String rewards = '/rewards';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    dashboard: (_) => const MainScreen(),
    habits: (_) => const HabitsScreen(),
    addHabit: (_) => const AddHabitScreen(),
    editHabit: (ctx) {
      final habit = ModalRoute.of(ctx)?.settings.arguments as Habit?;
      return AddEditHabitScreen(habit: habit);
    },
    progress: (_) => const ProgressScreen(),
    insights: (_) => const InsightsScreen(),
    rewards: (_) => const RewardsScreen(),
    settings: (_) => const SettingsScreen(),
  };

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) => Navigator.pushNamed<T>(context, route, arguments: arguments);

  static Future<T?> pushReplacementNamed<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) => Navigator.pushReplacementNamed<T, dynamic>(
    context,
    route,
    arguments: arguments,
  );
}
