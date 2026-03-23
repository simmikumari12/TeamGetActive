import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/database_service.dart';
import 'core/services/prefs_service.dart';
import 'data/repositories/challenge_repository.dart';

void main() async {
  // Required before any async work prior to runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Open (or create) the SQLite database — runs onCreate on first install
  await DatabaseService.instance.database;

  // Load SharedPreferences into memory so all getters are synchronous
  await PrefsService.instance.init();

  // Seed starter challenges if the table is empty
  await ChallengeRepository.instance.seedIfEmpty();

  runApp(const HabitMasteryApp());
}
