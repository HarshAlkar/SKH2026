import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gramin_health.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Patients logic
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        village TEXT NOT NULL,
        phone TEXT NOT NULL,
        bloodGroup TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        operationType TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create Health Records Table (Placeholder for feature expansion)
    await db.execute('''
      CREATE TABLE health_records (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        recordData TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  /// Helper generic method to insert to any table
  Future<void> insertData(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Helper generic method to retrieve all rows from a table
  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    final db = await database;
    return await db.query(table);
  }

  /// Helper generic method to update a row
  Future<void> updateData(
    String table,
    Map<String, dynamic> data,
    String id,
  ) async {
    final db = await database;
    await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  /// Helper generic method to delete a row
  Future<void> deleteData(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
