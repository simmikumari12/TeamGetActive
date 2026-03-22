import 'package:flutter/material.dart';
import '../../../widgets/common/bottom_nav_bar.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../habits/screens/habits_screen.dart';
import '../../progress/screens/progress_screen.dart';
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

  // Placeholder widget for tabs not yet implemented
  static Widget _placeholder(String label) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('$label — coming soon',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const HabitsScreen(),
    const ProgressScreen(),
    _placeholder('Insights'),
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
