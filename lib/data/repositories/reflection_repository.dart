import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/weekly_reflection.dart';
import '../../core/services/database_service.dart';

/// CRUD access for the weekly_reflections table.
class ReflectionRepository {
  ReflectionRepository._();
  static final ReflectionRepository instance = ReflectionRepository._();

  /// Returns this week's reflection, or null if none exists yet.
  Future<WeeklyReflection?> getForWeek(DateTime weekStart) async {
    final db = await DatabaseService.instance.database;
    final key = weekStart.toIso8601String().substring(0, 10);
    final rows = await db.query(
      AppDatabase.tableWeeklyReflections,
      where: 'week_start = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeeklyReflection.fromMap(rows.first);
  }

  /// Inserts or replaces the reflection for the given week.
  Future<void> upsert(WeeklyReflection reflection) async {
    final db = await DatabaseService.instance.database;
    await db.insert(
      AppDatabase.tableWeeklyReflections,
      reflection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the last [limit] reflections ordered newest first.
  Future<List<WeeklyReflection>> getRecent({int limit = 4}) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      AppDatabase.tableWeeklyReflections,
      orderBy: 'week_start DESC',
      limit: limit,
    );
    return rows.map(WeeklyReflection.fromMap).toList();
  }

  Future<int> count() async {
    final db = await DatabaseService.instance.database;
    final result = await db
        .rawQuery('SELECT COUNT(*) FROM ${AppDatabase.tableWeeklyReflections}');
    return result.first.values.first as int;
  }
}
