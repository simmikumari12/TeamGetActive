import 'dart:async';

import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/buddy_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../data/models/habit.dart';
import '../../../data/models/habit_log.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/log_repository.dart';

/// Main dashboard screen — first tab users see after onboarding.
/// Shows today's habits, streak summary, and XP progress.
class DashboardScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshSignal;
  const DashboardScreen({super.key, this.refreshSignal});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Habit> _habits = [];
  Set<int> _completedToday = {};
  Set<int> _missedYesterday = {};
  Map<int, int> _weeklyProgress = {};
  String _buddyMessage = '';
  String _microGoal = '';
  bool _loading = true;

  DateTime get _today => DateTime.now();

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
    final today = _today;
    final yesterday = today.subtract(const Duration(days: 1));

    final habits = await HabitRepository.instance.getAll();
    final completedToday =
        await LogRepository.instance.getCompletedHabitIdsForDate(today);
    final completedYesterday =
        await LogRepository.instance.getCompletedHabitIdsForDate(yesterday);

    // Weekly progress: count logs this Mon–Sun for weekly habits
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final Map<int, int> weeklyProgress = {};
    for (final h in habits.where((h) => h.frequencyType == 'weekly')) {
      weeklyProgress[h.id!] =
          await LogRepository.instance.countInRange(h.id!, weekStart, weekEnd);
    }

    // Daily habits not logged yesterday = missed.
    // Exclude habits created today — they couldn't have been done yesterday.
    final todayStart = DateTime(today.year, today.month, today.day);
    final missed = habits
        .where((h) =>
            h.frequencyType == 'daily' &&
            !completedYesterday.contains(h.id) &&
            h.createdAt.isBefore(todayStart))
        .map((h) => h.id!)
        .toSet();

    final (buddyMsg, microGoal) = await BuddyService.instance.getMessages();

    if (!mounted) return;
    setState(() {
      _habits = habits;
      _completedToday = completedToday;
      _missedYesterday = missed;
      _weeklyProgress = weeklyProgress;
      _buddyMessage = buddyMsg;
      _microGoal = microGoal;
      _loading = false;
    });
  }

  Future<void> _toggleHabit(Habit habit) async {
    final id = habit.id!;
    if (_completedToday.contains(id)) {
      await LogRepository.instance.deleteForDate(id, _today);
      setState(() => _completedToday.remove(id));
    } else {
      final points = (AppConstants.basePointsPerCompletion *
              (AppConstants.difficultyMultipliers[habit.difficulty] ?? 1.0))
          .toInt();
      await LogRepository.instance.insert(
        HabitLog(
          habitId: id,
          completedDate: _today,
          pointsEarned: points,
        ),
      );
      await BadgeService.instance.checkAll();
      setState(() => _completedToday.add(id));
    }
  }

  String get _greeting {
    final hour = _today.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = PrefsService.instance.userName;
    final done = _completedToday.length;
    final total = _habits.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_greeting, $name 👋',
                style: AppTextStyles.headlineMedium),
            Text('Today\'s missions', style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProgressCard(done: done, total: total),
                  const SizedBox(height: 12),
                  const _DayTimerCard(),
                  const SizedBox(height: 12),
                  _BuddyCard(
                    message: _buddyMessage,
                    microGoal: _microGoal,
                    personality: PrefsService.instance.buddyPersonality,
                  ),
                  const SizedBox(height: 16),
                  if (_habits.isEmpty)
                    _EmptyState()
                  else
                    _HabitList(
                      habits: _habits,
                      completedIds: _completedToday,
                      missedYesterday: _missedYesterday,
                      weeklyProgress: _weeklyProgress,
                      onToggle: _toggleHabit,
                    ),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress summary card
// ---------------------------------------------------------------------------

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
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
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.accentGold, size: 22),
              const SizedBox(width: 8),
              Text('$done / $total habits done',
                  style: AppTextStyles.titleLarge
                      .copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppColors.accentGold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Add your first habit below!'
                : done == total
                    ? 'All missions complete! 🎉'
                    : '${total - done} remaining today',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit list
// ---------------------------------------------------------------------------

class _HabitList extends StatelessWidget {
  final List<Habit> habits;
  final Set<int> completedIds;
  final Set<int> missedYesterday;
  final Map<int, int> weeklyProgress;
  final ValueChanged<Habit> onToggle;

  const _HabitList({
    required this.habits,
    required this.completedIds,
    required this.missedYesterday,
    required this.weeklyProgress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final pending =
        habits.where((h) => !completedIds.contains(h.id)).toList();
    final done = habits.where((h) => completedIds.contains(h.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pending ──────────────────────────────────────────
        Text('Today\'s Habits', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('All done for today! 🎉',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textLight)),
            ),
          )
        else
          ...pending.map((h) => _HabitTile(
                habit: h,
                isDone: false,
                missedYesterday: missedYesterday.contains(h.id),
                weeklyCount: weeklyProgress[h.id],
                onToggle: () => onToggle(h),
              )),

        // ── Completed ─────────────────────────────────────────
        if (done.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Completed', style: AppTextStyles.headlineMedium),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${done.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...done.map((h) => _HabitTile(
                habit: h,
                isDone: true,
                weeklyCount: weeklyProgress[h.id],
                onToggle: () => onToggle(h),
              )),
        ],
      ],
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final bool isDone;
  final bool missedYesterday;
  final int? weeklyCount;
  final VoidCallback onToggle;

  const _HabitTile({
    required this.habit,
    required this.isDone,
    required this.onToggle,
    this.missedYesterday = false,
    this.weeklyCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[
        habit.colorIndex.clamp(0, AppColors.categoryColors.length - 1)];

    final isWeekly = habit.frequencyType == 'weekly';
    final weekCount = weeklyCount ?? 0;
    final weekComplete = isWeekly && weekCount >= habit.targetCount;

    // Subtitle text
    String subtitleText = habit.category;
    if (isWeekly && habit.targetCount > 1) {
      subtitleText = '${habit.category} • $weekCount/${habit.targetCount} days this week';
    }

    // Border color: week-complete overrides normal done state for weekly habits
    final borderColor = weekComplete
        ? Colors.green
        : isDone
            ? color
            : missedYesterday
                ? Colors.orange
                : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDone
            ? color.withValues(alpha: 0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.star, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                habit.title,
                style: AppTextStyles.titleLarge.copyWith(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? AppColors.textLight : AppColors.textDark,
                ),
              ),
            ),
            if (weekComplete)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Week done',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            if (!isDone && missedYesterday && !isWeekly)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 16),
              ),
          ],
        ),
        subtitle: Text(subtitleText, style: AppTextStyles.caption),
        trailing: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isDone ? color : AppColors.textLight),
            ),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day timer — shows time left today and explains the midnight reset
// ---------------------------------------------------------------------------

class _DayTimerCard extends StatefulWidget {
  const _DayTimerCard();

  @override
  State<_DayTimerCard> createState() => _DayTimerCardState();
}

class _DayTimerCardState extends State<_DayTimerCard> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = 24 * 60 * 60;
    final elapsed = _now.hour * 3600 + _now.minute * 60;
    final progress = elapsed / totalSeconds;
    final hoursLeft = 23 - _now.hour;
    final minsLeft = 59 - _now.minute;
    final timeLabel = hoursLeft > 0
        ? '$hoursLeft hr ${minsLeft.toString().padLeft(2, '0')} min left today'
        : '$minsLeft min left today';

    final Color urgencyColor;
    if (hoursLeft >= 6) {
      urgencyColor = Colors.green;
    } else if (hoursLeft >= 2) {
      urgencyColor = Colors.orange;
    } else {
      urgencyColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: urgencyColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeLabel,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textDark)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.lightDivider,
                    valueColor: AlwaysStoppedAnimation(urgencyColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Resets midnight',
              style: AppTextStyles.caption
                  .copyWith(color: urgencyColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Buddy card — daily pep message + micro-goal
// ---------------------------------------------------------------------------

class _BuddyCard extends StatelessWidget {
  final String message;
  final String microGoal;
  final String personality;

  const _BuddyCard({
    required this.message,
    required this.microGoal,
    required this.personality,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primaryPurple,
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(personality,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primaryPurple)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Daily',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pep message
          Text(message, style: AppTextStyles.bodyMedium),
          // Micro-goal
          if (microGoal.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_rounded,
                      color: AppColors.primaryPurple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(microGoal,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/buddy-chat'),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Chat with Buddy'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPurple,
                textStyle: AppTextStyles.labelLarge,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.add_task_rounded,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('No habits yet', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text('Tap the Habits tab to create your first mission.',
              style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
