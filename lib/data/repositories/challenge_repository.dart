import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/challenge.dart';
import '../../core/services/database_service.dart';

/// CRUD access for the challenges table.
class ChallengeRepository {
  ChallengeRepository._();
  static final ChallengeRepository instance = ChallengeRepository._();

  /// Returns all active challenges ordered by reward points descending.
  Future<List<Challenge>> getActive() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      AppDatabase.tableChallenges,
      where: 'is_active = 1',
      orderBy: 'reward_points DESC',
    );
    return rows.map(Challenge.fromMap).toList();
  }

  Future<List<Challenge>> getAll() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(AppDatabase.tableChallenges, orderBy: 'id ASC');
    return rows.map(Challenge.fromMap).toList();
  }

  Future<int> insert(Challenge challenge) async {
    final db = await DatabaseService.instance.database;
    return db.insert(AppDatabase.tableChallenges, challenge.toMap());
  }

  Future<void> deactivate(int id) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      AppDatabase.tableChallenges,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Seeds starter challenges if the table is empty.
  Future<void> seedIfEmpty() async {
    final db = await DatabaseService.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${AppDatabase.tableChallenges}'),
    );
    if ((count ?? 0) > 0) return;
    final now = DateTime.now();
    final batch = db.batch();
    for (final c in _starterChallenges(now)) {
      batch.insert(AppDatabase.tableChallenges, c.toMap());
    }
    await batch.commit();
  }

  static List<Challenge> _starterChallenges(DateTime now) => [
        Challenge(
          title: '3-Day Ignition',
          description: 'Hit a 3-day streak on any habit.',
          challengeType: 'streak',
          targetValue: 3,
          rewardPoints: 50,
          createdAt: now,
        ),
        Challenge(
          title: 'Week Warrior',
          description: 'Log completions 7 days in a row.',
          challengeType: 'streak',
          targetValue: 7,
          rewardPoints: 150,
          createdAt: now,
        ),
        Challenge(
          title: 'Half Century',
          description: 'Record 50 total habit completions.',
          challengeType: 'completion_count',
          targetValue: 50,
          rewardPoints: 200,
          createdAt: now,
        ),
        Challenge(
          title: 'Perfect Week',
          description: 'Complete every habit for 7 consecutive days.',
          challengeType: 'perfect_week',
          targetValue: 7,
          rewardPoints: 300,
          createdAt: now,
        ),
      ];
}
