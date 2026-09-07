import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Service untuk mengelola database SQLite lokal.
///
/// Menyediakan cache offline untuk data pertumbuhan anak
/// yang belum tersinkron ke server.
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  static const String _dbName = 'pediagrow.db';
  static const int _dbVersion = 1;
  static const String tableGrowthCache = 'growth_records_cache';

  Database? _database;

  /// Mengembalikan instance database, membuat jika belum ada.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableGrowthCache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        berat_kg REAL,
        tinggi_cm REAL,
        lingkar_kepala_cm REAL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Menyisipkan record pertumbuhan baru ke cache lokal.
  ///
  /// [record] berupa `Map<String, dynamic>` dengan key sesuai kolom tabel.
  /// Mengembalikan `id` dari row yang baru disisipkan.
  Future<int> insertGrowthRecord(Map<String, dynamic> record) async {
    final db = await database;
    return db.insert(
      tableGrowthCache,
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua record yang belum tersinkron (`synced = 0`).
  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final db = await database;
    return db.query(
      tableGrowthCache,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  /// Menandai record sebagai sudah tersinkron (`synced = 1`).
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return db.update(
      tableGrowthCache,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menutup koneksi database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
