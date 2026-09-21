import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/artikel_model.dart';

/// Service repositori untuk mengelola data Artikel Kesehatan di SQLite lokal.
///
/// Bertindak sebagai single source of truth untuk:
/// - Sisi Pengguna: `ArtikelKesehatanPage`, `DetailArtikelPage`
/// - Sisi PMIK/Superadmin: Pengelolaan artikel (tambah, edit, hapus, kelola konten)
///
/// Mendukung:
/// 1. Penyimpanan persisten di SQLite lokal (`pediagrow_artikel.db`).
/// 2. Pembaruan reaktif via [articlesNotifier] sehingga ketika PMIK melakukan
///    perubahan pada database, UI pengguna otomatis terbarui tanpa perlu reload manual.
/// 3. Pencarian dinamis berbasis kata kunci judul artikel.
/// 4. Simulasi empty state (ketika database belum diisi artikel oleh PMIK).
class ArtikelService {
  static final ArtikelService _instance = ArtikelService._internal();
  factory ArtikelService() => _instance;
  ArtikelService._internal();

  static const String _dbName = 'pediagrow_artikel.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'artikel_kesehatan';

  Database? _db;
  final ValueNotifier<List<ArtikelModel>> _articlesNotifier =
      ValueNotifier<List<ArtikelModel>>([]);

  /// Notifier untuk mendengarkan perubahan daftar artikel secara real-time
  ValueListenable<List<ArtikelModel>> get articlesNotifier => _articlesNotifier;

  /// Mengambil daftar artikel saat ini di memori (unmodifiable)
  List<ArtikelModel> get currentArticles =>
      List<ArtikelModel>.unmodifiable(_articlesNotifier.value);

  /// Inisialisasi atau mendapatkan instance database SQLite
  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
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
      CREATE TABLE $_tableName (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        judul            TEXT    NOT NULL,
        kategori         TEXT    NOT NULL DEFAULT 'Artikel',
        sub_kategori     TEXT    DEFAULT '[]',
        tanggal          TEXT    NOT NULL DEFAULT '',
        asset_image_path TEXT,
        image_url        TEXT,
        penulis          TEXT    DEFAULT 'Pego',
        deskripsi        TEXT,
        pengertian       TEXT,
        isi_lengkap      TEXT    DEFAULT ''
      )
    ''');

    // Seed data awal default sesuai referensi desain
    final batch = db.batch();
    for (final artikel in ArtikelModel.seedArticles) {
      batch.insert(_tableName, artikel.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Memuat seluruh artikel dari database ke notifier memori
  Future<List<ArtikelModel>> getAllArticles({String? searchQuery}) async {
    final db = await _database;
    List<Map<String, dynamic>> maps;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final clean = '%${searchQuery.trim()}%';
      maps = await db.query(
        _tableName,
        where: 'judul LIKE ?',
        whereArgs: [clean],
        orderBy: 'id ASC',
      );
    } else {
      maps = await db.query(
        _tableName,
        orderBy: 'id ASC',
      );
    }

    final list = maps.map((m) => ArtikelModel.fromMap(m)).toList();
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      _articlesNotifier.value = list;
    }
    return list;
  }


  /// Mengambil satu artikel berdasarkan ID
  Future<ArtikelModel?> getArticleById(int id) async {
    final db = await _database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ArtikelModel.fromMap(maps.first);
  }

  /// Filter lokal cepat untuk live searching judul
  List<ArtikelModel> filterArticles(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return currentArticles;
    }
    return currentArticles.where((art) {
      return art.judul.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // MANAJEMEN DATA OLEH PMIK (ADMIN & SUPERADMIN)
  // ---------------------------------------------------------------------------

  /// Tambah artikel baru ke database oleh PMIK
  Future<int> tambahArtikel(ArtikelModel artikel) async {
    final db = await _database;
    final id = await db.insert(
      _tableName,
      artikel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await getAllArticles(); // Perbarui memori & trigger listener
    return id;
  }

  /// Perbarui artikel yang ada oleh PMIK
  Future<int> updateArtikel(ArtikelModel artikel) async {
    if (artikel.id == null) return 0;
    final db = await _database;
    final count = await db.update(
      _tableName,
      artikel.toMap(),
      where: 'id = ?',
      whereArgs: [artikel.id],
    );
    await getAllArticles(); // Perbarui memori & trigger listener
    return count;
  }

  /// Hapus artikel dari database oleh PMIK
  Future<int> hapusArtikel(int id) async {
    final db = await _database;
    final count = await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    await getAllArticles(); // Perbarui memori & trigger listener
    return count;
  }

  /// Kosongkan seluruh artikel (berguna untuk simulasi/testing empty state)
  Future<void> clearAllArticles() async {
    final db = await _database;
    await db.delete(_tableName);
    _articlesNotifier.value = [];
  }

  /// Reset data kembali ke 3 artikel default referensi
  Future<void> resetToDefault() async {
    final db = await _database;
    await db.delete(_tableName);
    final batch = db.batch();
    for (final artikel in ArtikelModel.seedArticles) {
      batch.insert(_tableName, artikel.toMap());
    }
    await batch.commit(noResult: true);
    await getAllArticles();
  }
}
