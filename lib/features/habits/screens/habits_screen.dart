import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/habit.dart';
import '../../../data/repositories/habit_repository.dart';
import 'add_edit_habit_screen.dart';

/// Displays all active habits and allows create, edit, and archive actions.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await HabitRepository.instance.getAll();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _loading = false;
    });
  }

  Future<void> _openAddEdit({Habit? habit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditHabitScreen(habit: habit),
      ),
    );
    if (result == true) _loadHabits();
  }

  Future<void> _archiveHabit(Habit habit) async {
    await HabitRepository.instance.archive(habit.id!);
    _loadHabits();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${habit.title} archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await HabitRepository.instance.update(
              habit.copyWith(isArchived: false),
            );
            _loadHabits();
          },
        ),
      ),
    );
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
            'All logs for "${habit.title}" will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.accentRed))),
        ],
      ),
    );
    if (confirm == true) {
      await HabitRepository.instance.delete(habit.id!);
      _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Habits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? _EmptyState(onAdd: () => _openAddEdit())
              : RefreshIndicator(
                  onRefresh: _loadHabits,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _habits.length,
                    itemBuilder: (_, i) => _HabitCard(
                      habit: _habits[i],
                      onEdit: () => _openAddEdit(habit: _habits[i]),
                      onArchive: () => _archiveHabit(_habits[i]),
                      onDelete: () => _deleteHabit(_habits[i]),
                    ),
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit card with swipe-to-archive
// ---------------------------------------------------------------------------

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[
        habit.colorIndex.clamp(0, AppColors.categoryColors.length - 1)];

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.archive_outlined, color: AppColors.accentRed),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onArchive(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.star_rounded, color: color),
          ),
          title: Text(habit.title, style: AppTextStyles.titleLarge),
          subtitle: Text(
            '${habit.category} · ${habit.difficulty}',
            style: AppTextStyles.caption,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'archive') onArchive();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'archive', child: Text('Archive')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AppColors.accentRed))),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_task_rounded,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('No habits yet', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text('Create your first mission to get started.',
              style: AppTextStyles.bodyLarge),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create habit'),
          ),
        ],
      ),
    );
  }
}
