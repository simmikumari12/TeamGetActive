import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_nav_bar.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../habits/screens/habits_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../insights/screens/insights_screen.dart';
import '../../rewards/screens/rewards_screen.dart';

/// Shell screen that holds the bottom navigation bar and switches
/// between the 5 main tabs using an IndexedStack (preserves scroll state).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const HabitsScreen(),
    const ProgressScreen(),
    const InsightsScreen(),
    const RewardsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
