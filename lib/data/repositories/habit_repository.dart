import '../database/app_database.dart';
import '../models/habit.dart';
import '../../core/services/database_service.dart';

/// CRUD operations for the habits table.
class HabitRepository {
  HabitRepository._();
  static final HabitRepository instance = HabitRepository._();

  Future<int> insert(Habit habit) async {
    final db = await DatabaseService.instance.database;
    return db.insert(AppDatabase.tableHabits, habit.toMap());
  }

  Future<List<Habit>> getAll({bool includeArchived = false}) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      AppDatabase.tableHabits,
      where: includeArchived ? null : 'is_archived = ?',
      whereArgs: includeArchived ? null : [0],
      orderBy: 'created_at ASC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> getById(int id) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      AppDatabase.tableHabits,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Habit.fromMap(rows.first);
  }

  Future<int> update(Habit habit) async {
    final db = await DatabaseService.instance.database;
    return db.update(
      AppDatabase.tableHabits,
      habit.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> archive(int id) async {
    final db = await DatabaseService.instance.database;
    return db.update(
      AppDatabase.tableHabits,
      {'is_archived': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseService.instance.database;
    // habit_logs rows are removed by ON DELETE CASCADE
    return db.delete(AppDatabase.tableHabits, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppDatabase.tableHabits} WHERE is_archived = 0',
    );
    return result.first['c'] as int;
  }
}
