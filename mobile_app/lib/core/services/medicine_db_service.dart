import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/medicine_model.dart';

class MedicineDbService {
  static final MedicineDbService instance = MedicineDbService._init();
  static Database? _database;

  MedicineDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medicines.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_name TEXT NOT NULL,
        dosage TEXT,
        frequency TEXT,
        start_date TEXT,
        end_date TEXT,
        reminder_time TEXT,
        instructions TEXT,
        is_taken INTEGER,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0 -- 0: pending, 1: synced
      )
    ''');
  }

  Future<int> insert(MedicineModel medicine) async {
    final db = await instance.database;
    return await db.insert('medicines', medicine.toMap());
  }

  Future<List<MedicineModel>> getAllMedicines() async {
    final db = await instance.database;
    final result = await db.query('medicines', orderBy: 'created_at ASC');
    return result.map((json) => MedicineModel.fromMap(json)).toList();
  }

  Future<List<MedicineModel>> getTodaysMedicines(String dateStr) async {
    final db = await instance.database;
    // Simple filter: date is between start and end
    final result = await db.query(
      'medicines',
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [dateStr, dateStr],
    );
    return result.map((json) => MedicineModel.fromMap(json)).toList();
  }

  Future<int> update(MedicineModel medicine) async {
    final db = await instance.database;
    return await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
