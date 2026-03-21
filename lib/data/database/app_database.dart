import 'package:sqflite/sqflite.dart';

/// Defines all SQLite table schemas and handles DB creation/migration.
/// Called by DatabaseService via openDatabase callbacks.
class AppDatabase {
  AppDatabase._();

  // Table name constants reused by repositories
  static const String tableHabits = 'habits';
  static const String tableHabitLogs = 'habit_logs';
  static const String tableWeeklyReflections = 'weekly_reflections';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableChallenges = 'challenges';

  /// Runs on first install — creates all tables and seeds badge data.
  static Future<void> onCreate(Database db, int version) async {
    final batch = db.batch();
    _createHabitsTable(batch);
    _createHabitLogsTable(batch);
    _createWeeklyReflectionsTable(batch);
    _createBadgesTable(batch);
    _createUserBadgesTable(batch);
    _createChallengesTable(batch);
    await batch.commit();
    await _seedBadges(db);
  }

  /// Runs when dbVersion is bumped — add migration logic here in future.
  static Future<void> onUpgrade(Database db, int oldV, int newV) async {}

  static void _createHabitsTable(Batch b) => b.execute('''
    CREATE TABLE $tableHabits (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      title           TEXT    NOT NULL,
      description     TEXT,
      category        TEXT    NOT NULL DEFAULT 'Other',
      difficulty      TEXT    NOT NULL DEFAULT 'medium',
      frequency_type  TEXT    NOT NULL DEFAULT 'daily',
      target_count    INTEGER NOT NULL DEFAULT 1,
      color_index     INTEGER NOT NULL DEFAULT 0,
      icon_name       TEXT    NOT NULL DEFAULT 'star',
      created_at      TEXT    NOT NULL,
      updated_at      TEXT    NOT NULL,
      is_archived     INTEGER NOT NULL DEFAULT 0
    )
  ''');

  static void _createHabitLogsTable(Batch b) {
    b.execute('''
      CREATE TABLE $tableHabitLogs (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id          INTEGER NOT NULL,
        completed_date    TEXT    NOT NULL,
        completion_value  INTEGER NOT NULL DEFAULT 1,
        notes             TEXT,
        mood_tag          TEXT,
        points_earned     INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (habit_id) REFERENCES $tableHabits (id) ON DELETE CASCADE
      )
    ''');
    // Index for fast streak and date-range queries
    b.execute(
      'CREATE INDEX idx_logs_habit_date ON $tableHabitLogs (habit_id, completed_date)',
    );
  }

  static void _createWeeklyReflectionsTable(Batch b) => b.execute('''
    CREATE TABLE $tableWeeklyReflections (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      week_start      TEXT    NOT NULL UNIQUE,
      reflection_text TEXT,
      wins_text       TEXT,
      obstacles_text  TEXT,
      next_focus_text TEXT,
      created_at      TEXT    NOT NULL
    )
  ''');

  static void _createBadgesTable(Batch b) => b.execute('''
    CREATE TABLE $tableBadges (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      code             TEXT NOT NULL UNIQUE,
      title            TEXT NOT NULL,
      description      TEXT NOT NULL,
      unlock_condition TEXT NOT NULL,
      icon_name        TEXT NOT NULL DEFAULT 'emoji_events'
    )
  ''');

  static void _createUserBadgesTable(Batch b) => b.execute('''
    CREATE TABLE $tableUserBadges (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      badge_id    INTEGER NOT NULL,
      unlocked_at TEXT    NOT NULL,
      FOREIGN KEY (badge_id) REFERENCES $tableBadges (id)
    )
  ''');

  static void _createChallengesTable(Batch b) => b.execute('''
    CREATE TABLE $tableChallenges (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      title           TEXT    NOT NULL,
      description     TEXT    NOT NULL,
      challenge_type  TEXT    NOT NULL DEFAULT 'streak',
      target_value    INTEGER NOT NULL DEFAULT 7,
      reward_points   INTEGER NOT NULL DEFAULT 100,
      is_active       INTEGER NOT NULL DEFAULT 1,
      created_at      TEXT    NOT NULL
    )
  ''');

  /// Pre-loads all badge definitions so the rewards screen has data immediately.
  static Future<void> _seedBadges(Database db) async {
    const badges = [
      {'code': 'first_log',      'title': 'First Step',      'description': 'Complete your very first habit.',               'unlock_condition': 'Complete 1 habit log.',             'icon_name': 'flag'},
      {'code': 'streak_3',       'title': 'Hat Trick',       'description': '3-day streak on any habit.',                   'unlock_condition': 'Maintain a 3-day streak.',          'icon_name': 'local_fire_department'},
      {'code': 'streak_7',       'title': 'Week Warrior',    'description': '7-day streak on any habit.',                   'unlock_condition': 'Maintain a 7-day streak.',          'icon_name': 'military_tech'},
      {'code': 'streak_14',      'title': 'Fortnight Force', 'description': '14-day streak on any habit.',                  'unlock_condition': 'Maintain a 14-day streak.',         'icon_name': 'workspace_premium'},
      {'code': 'streak_30',      'title': 'Monthly Master',  'description': '30-day streak on any habit.',                  'unlock_condition': 'Maintain a 30-day streak.',         'icon_name': 'emoji_events'},
      {'code': 'habits_5',       'title': 'Mission Creator', 'description': 'Create 5 habits.',                             'unlock_condition': 'Have 5 habits created.',            'icon_name': 'add_task'},
      {'code': 'logs_50',        'title': 'Half Century',    'description': 'Log 50 habit completions.',                    'unlock_condition': 'Complete 50 total habit logs.',     'icon_name': 'star'},
      {'code': 'logs_100',       'title': 'Centurion',       'description': 'Log 100 habit completions.',                   'unlock_condition': 'Complete 100 total habit logs.',    'icon_name': 'stars'},
      {'code': 'perfect_week',   'title': 'Perfect Week',    'description': 'Complete all habits every day for a full week.','unlock_condition': '100% completion in any 7-day period.','icon_name': 'verified'},
      {'code': 'first_reflect',  'title': 'Self-Aware',      'description': 'Submit your first weekly reflection.',         'unlock_condition': 'Complete 1 weekly reflection.',     'icon_name': 'psychology'},
    ];
    final batch = db.batch();
    for (final badge in badges) {
      batch.insert(tableBadges, badge);
    }
    await batch.commit();
  }
}
