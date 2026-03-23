import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/theme_notifier.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget of Habit Mastery League.
class HabitMasteryApp extends StatelessWidget {
  const HabitMasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeNotifier>().mode;
    return MaterialApp(
      title: 'Habit Mastery League',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
