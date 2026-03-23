import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/streak_utils.dart';
import '../../../data/models/habit.dart';
import '../../../data/models/habit_log.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/log_repository.dart';

/// Progress tab — per-habit streaks, 28-day heatmap, and overall XP stats.
class ProgressScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshSignal;
  const ProgressScreen({super.key, this.refreshSignal});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Habit> _habits = [];
  Map<int, List<HabitLog>> _logsByHabit = {};
  List<HabitLog> _allLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.refreshSignal?.addListener(_loadData);
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final habits = await HabitRepository.instance.getAll();
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 90));
    final Map<int, List<HabitLog>> logsByHabit = {};
    final List<HabitLog> allLogs = [];
    for (final h in habits) {
      final logs =
          await LogRepository.instance.getLogsInRange(h.id!, from, now);
      logsByHabit[h.id!] = logs;
      allLogs.addAll(logs);
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _logsByHabit = logsByHabit;
      _allLogs = allLogs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? Center(
                  child: Text(
                    'No habits yet — add one to track progress.',
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _OverallStatsCard(logs: _allLogs),
                      const SizedBox(height: 20),
                      Text('Habit Streaks',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 12),
                      ..._habits.map((h) => _HabitProgressCard(
                            habit: h,
                            logs: _logsByHabit[h.id!] ?? [],
                          )),
                    ],
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overall XP / level stats card
// ---------------------------------------------------------------------------

class _OverallStatsCard extends StatelessWidget {
  final List<HabitLog> logs;
  const _OverallStatsCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final totalXp = StreakUtils.computeTotalXp(logs);
    final level = StreakUtils.computeLevel(totalXp);
    final xpIn = StreakUtils.xpIntoCurrentLevel(totalXp);
    final xpNeeded = StreakUtils.xpToNextLevel(totalXp);
    final rate7 = StreakUtils.completionRate(logs, 7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.primaryPurpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: Colors.white)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$totalXp XP',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: xpIn / (xpIn + xpNeeded),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accentGold),
            ),
          ),
          const SizedBox(height: 6),
          Text('$xpNeeded XP to Level ${level + 1}',
              style: AppTextStyles.caption.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '${(rate7 * 100).toStringAsFixed(0)}% completion this week',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-habit card with streak count and 28-day heatmap
// ---------------------------------------------------------------------------

class _HabitProgressCard extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;
  const _HabitProgressCard({required this.habit, required this.logs});

  @override
  Widget build(BuildContext context) {
    final isWeekly = habit.frequencyType == 'weekly';
    final streak = isWeekly
        ? StreakUtils.computeWeeklyStreak(logs, habit.targetCount)
        : StreakUtils.computeStreak(logs);
    final streakLabel = isWeekly ? 'wk streak' : 'day streak';
    final color = AppColors.categoryColors[
        habit.colorIndex.clamp(0, AppColors.categoryColors.length - 1)];
    final completed = StreakUtils.completedDates(logs);

    // For weekly habits show current-week count in the subtitle
    final weekCount = isWeekly ? StreakUtils.currentWeekCount(logs) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title, style: AppTextStyles.titleLarge),
                    if (weekCount != null)
                      Text(
                        '$weekCount/${habit.targetCount} days this week',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textLight),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.local_fire_department_rounded,
                color: streak > 0 ? AppColors.streakFire : AppColors.textLight,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '$streak $streakLabel',
                style: AppTextStyles.labelLarge.copyWith(
                    color: streak > 0
                        ? AppColors.streakFire
                        : AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HeatmapGrid(completedDates: completed, color: color),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 28-day completion heatmap grid
// ---------------------------------------------------------------------------

class _HeatmapGrid extends StatelessWidget {
  final Set<DateTime> completedDates;
  final Color color;
  const _HeatmapGrid({required this.completedDates, required this.color});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(28, (i) {
        final day =
            DateTime(today.year, today.month, today.day - (27 - i));
        final done = completedDates.contains(day);
        return Tooltip(
          message: done ? 'Done' : 'Missed',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: done ? color : AppColors.lightDivider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
