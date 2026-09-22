import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/resep_mpasi_model.dart';

/// Service untuk mengelola data Resep MPASI di SQLite lokal.
///
/// Bertindak sebagai single source of truth yang digunakan oleh:
/// - Halaman Pengguna: [DaftarResepPage], [DetailResepPage]
/// - Halaman PMIK/Superadmin: Untuk input, edit, dan pengelolaan resep
///
/// Fitur:
/// 1. Data awal (seed) memuat 7 resep resmi Kemenkes RI secara utuh (termasuk
///    resep ke-5 "Mie Kukus Telur Puyuh") dengan bahan dan langkah lengkap.
/// 2. Pembaruan reaktif melalui [recipesNotifier] sehingga setiap perubahan
///    oleh PMIK Superadmin langsung tercermin di halaman pengguna.
/// 3. Mekanisme pemulihan integritas data otomatis (_ensureDataIntegrity)
///    untuk memastikan perangkat dengan basis data lama langsung diperbarui.
class ResepMpasiService {
  static final ResepMpasiService _instance = ResepMpasiService._internal();
  factory ResepMpasiService() => _instance;
  ResepMpasiService._internal();

  static const String _dbName = 'pediagrow_resep.db';
  static const int _dbVersion = 3; // v3: tambah resep 8-10 (Kacang Hijau, Labu Salmon, Perkedel)
  static const String _tableName = 'resep_mpasi';

  Database? _db;

  /// Notifier reaktif untuk mendengarkan perubahan daftar resep secara real-time
  final ValueNotifier<List<ResepMpasiModel>> _recipesNotifier =
      ValueNotifier<List<ResepMpasiModel>>([]);
  ValueListenable<List<ResepMpasiModel>> get recipesNotifier =>
      _recipesNotifier;

  /// Ambil daftar resep terkini di memori
  List<ResepMpasiModel> get currentRecipes =>
      List<ResepMpasiModel>.unmodifiable(_recipesNotifier.value);

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Pastikan integritas data: jika resep lama memiliki bahan/langkah kosong, perbaiki
    await _ensureDataIntegrity(db);

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        judul            TEXT    NOT NULL,
        kategori_usia    TEXT    NOT NULL DEFAULT 'Semua',
        tanggal          TEXT    NOT NULL DEFAULT '',
        asset_image_path TEXT,
        image_url        TEXT,
        penulis          TEXT,
        energi_kkal      REAL,
        lemak_gr         REAL,
        protein_gr       REAL,
        porsi            INTEGER,
        bahan            TEXT    DEFAULT '',
        bahan_pelapis    TEXT    DEFAULT '',
        buah             TEXT    DEFAULT '',
        cara_membuat     TEXT    DEFAULT ''
      )
    ''');

    // Seed data awal dari PMIK/Superadmin (7 resep default Kemenkes)
    await _seedDefaultRecipes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensureDataIntegrity(db);
    }
  }

  /// Memastikan 7 resep default Kemenkes memiliki bahan dan cara membuat yang lengkap.
  /// Jika database lokal sebelumnya memiliki data resep yang kosong atau rumpang,
  /// fungsi ini akan memperbaruinya secara otomatis.
  Future<void> _ensureDataIntegrity(Database db) async {
    for (final defaultRecipe in ResepMpasiModel.defaultKemenkesRecipes) {
      final existing = await db.query(
        _tableName,
        where: 'id = ? OR judul = ?',
        whereArgs: [defaultRecipe.id, defaultRecipe.judul],
        limit: 1,
      );

      if (existing.isEmpty) {
        // Belum ada di database, tambahkan
        await db.insert(_tableName, defaultRecipe.toMap());
      } else {
        final currentBahan = existing.first['bahan'] as String?;
        final currentCara = existing.first['cara_membuat'] as String?;

        // Jika bahan atau cara membuat kosong/rumpang, perbarui dengan data resmi
        if (currentBahan == null ||
            currentBahan.trim().isEmpty ||
            currentCara == null ||
            currentCara.trim().isEmpty ||
            (defaultRecipe.id == 1 && currentBahan.contains('nugget'))) {
          await db.update(
            _tableName,
            defaultRecipe.toMap(),
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
      }
    }
  }

  /// Seed 7 resep default resmi Kemenkes RI ke SQLite.
  Future<void> _seedDefaultRecipes(Database db) async {
    for (final recipe in ResepMpasiModel.defaultKemenkesRecipes) {
      await db.insert(
        _tableName,
        recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API (digunakan oleh pengguna maupun PMIK/Superadmin)
  // ---------------------------------------------------------------------------

  /// Ambil semua resep dengan filter kategoriUsia dan/atau kata kunci pencarian.
  Future<List<ResepMpasiModel>> getAllResep({
    String? kategoriUsia,
    String? searchQuery,
  }) async {
    final db = await _database;

    String where = '1=1';
    final whereArgs = <dynamic>[];

    if (kategoriUsia != null && kategoriUsia != 'Semua') {
      where += ' AND kategori_usia = ?';
      whereArgs.add(kategoriUsia);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where += ' AND LOWER(judul) LIKE ?';
      whereArgs.add('%${searchQuery.trim().toLowerCase()}%');
    }

    final maps = await db.query(
      _tableName,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id ASC',
    );

    final results = maps.map((m) => ResepMpasiModel.fromMap(m)).toList();

    // Perbarui notifier jika query tanpa filter
    if ((kategoriUsia == null || kategoriUsia == 'Semua') &&
        (searchQuery == null || searchQuery.trim().isEmpty)) {
      _recipesNotifier.value = results;
    }

    return results;
  }

  /// Ambil satu resep berdasarkan ID secara spesifik.
  Future<ResepMpasiModel?> getResepById(int id) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ResepMpasiModel.fromMap(maps.first);
  }

  /// Tambah resep baru (digunakan oleh PMIK/Superadmin).
  Future<int> insertResep(ResepMpasiModel resep) async {
    final db = await _database;
    final id = await db.insert(
      _tableName,
      resep.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _refreshNotifier();
    return id;
  }

  /// Update resep yang sudah ada (digunakan oleh PMIK/Superadmin).
  Future<int> updateResep(ResepMpasiModel resep) async {
    final db = await _database;
    final count = await db.update(
      _tableName,
      resep.toMap(),
      where: 'id = ?',
      whereArgs: [resep.id],
    );
    await _refreshNotifier();
    return count;
  }

  /// Hapus resep (digunakan oleh PMIK/Superadmin).
  Future<int> deleteResep(int id) async {
    final db = await _database;
    final count = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    await _refreshNotifier();
    return count;
  }

  /// Segarkan cache notifier di memori
  Future<void> _refreshNotifier() async {
    final db = await _database;
    final maps = await db.query(_tableName, orderBy: 'id ASC');
    _recipesNotifier.value =
        maps.map((m) => ResepMpasiModel.fromMap(m)).toList();
  }

  /// Reset data kembali ke 7 resep default Kemenkes
  Future<void> resetToDefault() async {
    final db = await _database;
    await db.delete(_tableName);
    await _seedDefaultRecipes(db);
    await _refreshNotifier();
  }

  /// Tutup koneksi database.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
