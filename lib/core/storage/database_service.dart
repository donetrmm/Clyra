import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../config/app_config.dart';

class DatabaseService {
  static const String _usersTable = 'users';
  static const String _passwordsTable = 'passwords';

  DatabaseService._();
  static final DatabaseService _instance = DatabaseService._();
  static DatabaseService get instance => _instance;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConfig.databaseName);

    return await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_usersTable (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        master_password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login_at TEXT NOT NULL,
        biometric_enabled INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $_passwordsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        website TEXT,
        notes TEXT,
        category TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_passwords_title ON $_passwordsTable(title)',
    );
    await db.execute(
      'CREATE INDEX idx_passwords_category ON $_passwordsTable(category)',
    );
    await db.execute(
      'CREATE INDEX idx_passwords_favorite ON $_passwordsTable(is_favorite)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(_usersTable, user);
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final result = await db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final result = await db.query(
      _usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> userExists(String email) async {
    final db = await database;
    final result = await db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> updateUser(String id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(_usersTable, user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertPassword(Map<String, dynamic> password) async {
    final db = await database;
    return await db.insert(_passwordsTable, password);
  }

  Future<List<Map<String, dynamic>>> getAllPasswords() async {
    final db = await database;
    return await db.query(_passwordsTable, orderBy: 'title ASC');
  }

  Future<List<Map<String, dynamic>>> getFavoritePasswords() async {
    final db = await database;
    return await db.query(
      _passwordsTable,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );
  }

  Future<List<Map<String, dynamic>>> searchPasswords(String query) async {
    final db = await database;
    return await db.query(
      _passwordsTable,
      where: 'title LIKE ? OR username LIKE ? OR website LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
  }

  Future<Map<String, dynamic>?> getPassword(String id) async {
    final db = await database;
    final result = await db.query(
      _passwordsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updatePassword(String id, Map<String, dynamic> password) async {
    final db = await database;
    return await db.update(
      _passwordsTable,
      password,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePassword(String id) async {
    final db = await database;
    return await db.delete(_passwordsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllPasswords() async {
    final db = await database;
    await db.delete(_passwordsTable);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
