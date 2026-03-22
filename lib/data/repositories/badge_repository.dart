import '../database/app_database.dart';
import '../models/badge_model.dart';
import '../models/user_badge.dart';
import '../../core/services/database_service.dart';

/// CRUD access for the badges and user_badges tables.
class BadgeRepository {
  BadgeRepository._();
  static final BadgeRepository instance = BadgeRepository._();

  Future<List<BadgeModel>> getAllBadges() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(AppDatabase.tableBadges, orderBy: 'id ASC');
    return rows.map(BadgeModel.fromMap).toList();
  }

  Future<List<UserBadge>> getUnlockedBadges() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      AppDatabase.tableUserBadges,
      orderBy: 'unlocked_at DESC',
    );
    return rows.map(UserBadge.fromMap).toList();
  }

  Future<Set<int>> getUnlockedBadgeIds() async {
    final unlocked = await getUnlockedBadges();
    return unlocked.map((u) => u.badgeId).toSet();
  }

  /// Records a new badge unlock. Skips if already unlocked.
  Future<void> unlock(int badgeId) async {
    final db = await DatabaseService.instance.database;
    final already = await db.query(
      AppDatabase.tableUserBadges,
      where: 'badge_id = ?',
      whereArgs: [badgeId],
      limit: 1,
    );
    if (already.isNotEmpty) return;
    await db.insert(AppDatabase.tableUserBadges, {
      'badge_id': badgeId,
      'unlocked_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns the BadgeModel for a given code, or null if not found.
  Future<BadgeModel?> getByCode(String code) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      AppDatabase.tableBadges,
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BadgeModel.fromMap(rows.first);
  }
}
