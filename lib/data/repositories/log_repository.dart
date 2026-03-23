import '../database/app_database.dart';
import '../models/habit_log.dart';
import '../../core/services/database_service.dart';

/// CRUD and query operations for the habit_logs table.
class LogRepository {
  LogRepository._();
  static final LogRepository instance = LogRepository._();

  Future<int> insert(HabitLog log) async {
    final db = await DatabaseService.instance.database;
    return db.insert(AppDatabase.tableHabitLogs, log.toMap());
  }

  /// Returns all logs for a specific habit on a given date (YYYY-MM-DD).
  Future<List<HabitLog>> getLogsForDate(int habitId, DateTime date) async {
    final db = await DatabaseService.instance.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      AppDatabase.tableHabitLogs,
      where: 'habit_id = ? AND completed_date = ?',
      whereArgs: [habitId, dateStr],
    );
    return rows.map(HabitLog.fromMap).toList();
  }

  /// Returns all habit IDs that were logged on a given date.
  Future<Set<int>> getCompletedHabitIdsForDate(DateTime date) async {
    final db = await DatabaseService.instance.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      AppDatabase.tableHabitLogs,
      columns: ['habit_id'],
      where: 'completed_date = ?',
      whereArgs: [dateStr],
    );
    return rows.map((r) => r['habit_id'] as int).toSet();
  }

  /// Returns all logs for a habit between two dates inclusive.
  Future<List<HabitLog>> getLogsInRange(
      int habitId, DateTime from, DateTime to) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      AppDatabase.tableHabitLogs,
      where: 'habit_id = ? AND completed_date BETWEEN ? AND ?',
      whereArgs: [
        habitId,
        from.toIso8601String().substring(0, 10),
        to.toIso8601String().substring(0, 10),
      ],
      orderBy: 'completed_date ASC',
    );
    return rows.map(HabitLog.fromMap).toList();
  }

  /// Deletes a log entry for a habit on a specific date (used to un-check).
  Future<int> deleteForDate(int habitId, DateTime date) async {
    final db = await DatabaseService.instance.database;
    return db.delete(
      AppDatabase.tableHabitLogs,
      where: 'habit_id = ? AND completed_date = ?',
      whereArgs: [habitId, date.toIso8601String().substring(0, 10)],
    );
  }

  /// Count of logs for a habit within a date range inclusive.
  /// Used for weekly-target progress (e.g. gym 4/7 days).
  Future<int> countInRange(int habitId, DateTime from, DateTime to) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppDatabase.tableHabitLogs} '
      'WHERE habit_id = ? AND completed_date BETWEEN ? AND ?',
      [
        habitId,
        from.toIso8601String().substring(0, 10),
        to.toIso8601String().substring(0, 10),
      ],
    );
    return result.first['c'] as int;
  }

  /// Total number of logs ever recorded — used for badge checks.
  Future<int> totalCount() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppDatabase.tableHabitLogs}',
    );
    return result.first['c'] as int;
  }
}
