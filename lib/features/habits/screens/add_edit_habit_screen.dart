import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/habit.dart';
import '../../../data/repositories/habit_repository.dart';

/// Form screen for creating a new habit or editing an existing one.
/// Returns true to the caller when a save succeeds.
class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit; // null = create mode, non-null = edit mode

  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _category = AppConstants.habitCategories.first;
  String _difficulty = 'medium';
  String _frequency = 'daily';
  int _colorIndex = 0;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final h = widget.habit!;
      _titleController.text = h.title;
      _descController.text = h.description ?? '';
      _category = h.category;
      _difficulty = h.difficulty;
      _frequency = h.frequencyType;
      _colorIndex = h.colorIndex;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    if (_isEditing) {
      await HabitRepository.instance.update(
        widget.habit!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          category: _category,
          difficulty: _difficulty,
          frequencyType: _frequency,
          colorIndex: _colorIndex,
          updatedAt: now,
        ),
      );
    } else {
      await HabitRepository.instance.insert(
        Habit(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          category: _category,
          difficulty: _difficulty,
          frequencyType: _frequency,
          colorIndex: _colorIndex,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Habit name *',
                hintText: 'e.g. Morning run',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Name is too short';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Why does this habit matter?',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Category chips
            Text('Category', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.habitCategories.map((c) {
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.primaryPurple,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textDark),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Difficulty
            Text('Difficulty', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                _DifficultyChip(
                    label: 'Easy',
                    color: AppColors.difficultyEasy,
                    selected: _difficulty == 'easy',
                    onTap: () => setState(() => _difficulty = 'easy')),
                const SizedBox(width: 10),
                _DifficultyChip(
                    label: 'Medium',
                    color: AppColors.difficultyMedium,
                    selected: _difficulty == 'medium',
                    onTap: () => setState(() => _difficulty = 'medium')),
                const SizedBox(width: 10),
                _DifficultyChip(
                    label: 'Hard',
                    color: AppColors.difficultyHard,
                    selected: _difficulty == 'hard',
                    onTap: () => setState(() => _difficulty = 'hard')),
              ],
            ),
            const SizedBox(height: 24),

            // Frequency toggle
            Text('Frequency', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) => setState(() => _frequency = s.first),
            ),
            const SizedBox(height: 24),

            // Color picker
            Text('Color tag', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: List.generate(AppColors.categoryColors.length, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.categoryColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _colorIndex == i
                            ? AppColors.textDark
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _colorIndex == i
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Create habit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge
              .copyWith(color: selected ? Colors.white : color),
        ),
      ),
    );
  }
}
