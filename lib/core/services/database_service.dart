import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/database/app_database.dart';
import '../constants/app_constants.dart';

/// Singleton service that owns the SQLite database connection.
/// All repositories obtain the database through this service.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  /// Returns the open database, initializing it on the first call.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: AppDatabase.onCreate,
      onUpgrade: AppDatabase.onUpgrade,
    );
  }

  /// Closes the database. Call only when the app is fully disposed.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
