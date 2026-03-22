import 'package:flutter/material.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/dashboard/screens/main_screen.dart';
import '../features/habits/screens/add_habit_screen.dart';
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
    habits: (_) => const _PlaceholderScreen(title: 'My Habits'),
    addHabit: (_) => const AddHabitScreen(),
    editHabit: (_) => const _PlaceholderScreen(title: 'Edit Habit'),
    progress: (_) => const ProgressScreen(),
    insights: (_) => const InsightsScreen(), // ← FIXED
    rewards: (_) => const RewardsScreen(), // ← FIXED
    settings: (_) => const SettingsScreen(), // ← FIXED
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '$title — coming soon',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
