import 'package:flutter/material.dart';
import '../features/splash/screens/splash_screen.dart';

/// Central route registry for Habit Mastery League.
/// Add new named routes here as screens are implemented.
class AppRouter {
  AppRouter._();

  // Route name constants — use these instead of raw strings throughout the app
  static const String splash      = '/';
  static const String onboarding  = '/onboarding';
  static const String dashboard   = '/dashboard';
  static const String habits      = '/habits';
  static const String addHabit    = '/habits/add';
  static const String editHabit   = '/habits/edit';
  static const String progress    = '/progress';
  static const String insights    = '/insights';
  static const String rewards     = '/rewards';
  static const String settings    = '/settings';

  /// Passed to MaterialApp.routes.
  static Map<String, WidgetBuilder> get routes => {
        splash:     (_) => const SplashScreen(),
        onboarding: (_) => const _PlaceholderScreen(title: 'Onboarding'),
        dashboard:  (_) => const _PlaceholderScreen(title: 'Dashboard'),
        habits:     (_) => const _PlaceholderScreen(title: 'My Habits'),
        addHabit:   (_) => const _PlaceholderScreen(title: 'Add Habit'),
        editHabit:  (_) => const _PlaceholderScreen(title: 'Edit Habit'),
        progress:   (_) => const _PlaceholderScreen(title: 'Progress'),
        insights:   (_) => const _PlaceholderScreen(title: 'Insights'),
        rewards:    (_) => const _PlaceholderScreen(title: 'Rewards'),
        settings:   (_) => const _PlaceholderScreen(title: 'Settings'),
      };

  /// Helper for pushing with a typed argument (e.g., habit id for edit screen).
  static Future<T?> pushNamed<T>(BuildContext context, String route,
          {Object? arguments}) =>
      Navigator.pushNamed<T>(context, route, arguments: arguments);

  static Future<T?> pushReplacementNamed<T>(BuildContext context, String route,
          {Object? arguments}) =>
      Navigator.pushReplacementNamed<T, dynamic>(context, route,
          arguments: arguments);
}

/// Temporary screen shown for routes not yet implemented.
/// Replaced one by one as each feature branch lands.
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
            const Icon(Icons.construction_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('$title — coming soon',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
