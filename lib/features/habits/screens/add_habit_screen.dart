import 'package:flutter/material.dart';
import 'add_edit_habit_screen.dart';

/// Thin wrapper kept for backwards-compatibility with any direct references.
/// Delegates to AddEditHabitScreen in create mode (no habit argument).
class AddHabitScreen extends StatelessWidget {
  const AddHabitScreen({super.key});

  @override
  Widget build(BuildContext context) => const AddEditHabitScreen();
}
