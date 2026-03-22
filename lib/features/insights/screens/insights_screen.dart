import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/buddy_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../data/models/weekly_reflection.dart';
import '../../../data/repositories/reflection_repository.dart';

/// Insights tab — AI buddy card and weekly reflection form.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String? _buddyMessage;
  WeeklyReflection? _thisWeek;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final msg = await BuddyService.instance.getMessage();
    final weekStart = _mondayOf(DateTime.now());
    final reflection =
        await ReflectionRepository.instance.getForWeek(weekStart);
    if (!mounted) return;
    setState(() {
      _buddyMessage = msg;
      _thisWeek = reflection;
      _loading = false;
    });
  }

  DateTime _mondayOf(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  void _openReflectionSheet() async {
    final weekStart = _mondayOf(DateTime.now());
    final result = await showModalBottomSheet<WeeklyReflection>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReflectionSheet(
        weekStart: weekStart,
        existing: _thisWeek,
      ),
    );
    if (result != null) {
      setState(() => _thisWeek = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BuddyCard(
                    message: _buddyMessage ?? '',
                    personality: PrefsService.instance.buddyPersonality,
                  ),
                  const SizedBox(height: 24),
                  Text('Weekly Reflection', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 12),
                  _thisWeek == null
                      ? _EmptyReflection(onTap: _openReflectionSheet)
                      : _ReflectionSummaryCard(
                          reflection: _thisWeek!,
                          onEdit: _openReflectionSheet,
                        ),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buddy card
// ---------------------------------------------------------------------------

class _BuddyCard extends StatelessWidget {
  final String message;
  final String personality;
  const _BuddyCard({required this.message, required this.personality});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.psychology_rounded,
                  color: AppColors.accentGold, size: 22),
              const SizedBox(width: 8),
              Text(personality,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.accentGold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty reflection state
// ---------------------------------------------------------------------------

class _EmptyReflection extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyReflection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.edit_note_rounded,
                size: 40, color: AppColors.primaryPurple),
            const SizedBox(height: 8),
            Text('Reflect on this week',
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.primaryPurple)),
            const SizedBox(height: 4),
            Text(
              'Capture your wins, obstacles, and focus for next week.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reflection summary card
// ---------------------------------------------------------------------------

class _ReflectionSummaryCard extends StatelessWidget {
  final WeeklyReflection reflection;
  final VoidCallback onEdit;
  const _ReflectionSummaryCard(
      {required this.reflection, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This Week', style: AppTextStyles.titleLarge),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          if (reflection.winsText != null && reflection.winsText!.isNotEmpty)
            _ReflectionRow(
                icon: Icons.celebration_rounded,
                color: AppColors.accentGreen,
                label: 'Wins',
                text: reflection.winsText!),
          if (reflection.obstaclesText != null &&
              reflection.obstaclesText!.isNotEmpty)
            _ReflectionRow(
                icon: Icons.warning_amber_rounded,
                color: AppColors.accentGold,
                label: 'Obstacles',
                text: reflection.obstaclesText!),
          if (reflection.nextFocusText != null &&
              reflection.nextFocusText!.isNotEmpty)
            _ReflectionRow(
                icon: Icons.arrow_forward_rounded,
                color: AppColors.primaryPurple,
                label: 'Next Focus',
                text: reflection.nextFocusText!),
        ],
      ),
    );
  }
}

class _ReflectionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String text;
  const _ReflectionRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.labelLarge.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(text, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reflection bottom sheet form
// ---------------------------------------------------------------------------

class _ReflectionSheet extends StatefulWidget {
  final DateTime weekStart;
  final WeeklyReflection? existing;
  const _ReflectionSheet({required this.weekStart, this.existing});

  @override
  State<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<_ReflectionSheet> {
  late final TextEditingController _winsCtrl;
  late final TextEditingController _obstaclesCtrl;
  late final TextEditingController _focusCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _winsCtrl =
        TextEditingController(text: widget.existing?.winsText ?? '');
    _obstaclesCtrl =
        TextEditingController(text: widget.existing?.obstaclesText ?? '');
    _focusCtrl =
        TextEditingController(text: widget.existing?.nextFocusText ?? '');
  }

  @override
  void dispose() {
    _winsCtrl.dispose();
    _obstaclesCtrl.dispose();
    _focusCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final reflection = WeeklyReflection(
      id: widget.existing?.id,
      weekStart: widget.weekStart,
      winsText: _winsCtrl.text.trim(),
      obstaclesText: _obstaclesCtrl.text.trim(),
      nextFocusText: _focusCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ReflectionRepository.instance.upsert(reflection);
    if (mounted) Navigator.pop(context, reflection);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Weekly Reflection', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 20),
          _Field(
              controller: _winsCtrl,
              label: 'Wins this week',
              hint: 'What went well?'),
          const SizedBox(height: 12),
          _Field(
              controller: _obstaclesCtrl,
              label: 'Obstacles',
              hint: 'What got in your way?'),
          const SizedBox(height: 12),
          _Field(
              controller: _focusCtrl,
              label: 'Next week focus',
              hint: 'What will you prioritise?'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Reflection'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _Field(
      {required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
    );
  }
}
