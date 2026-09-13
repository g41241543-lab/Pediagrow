import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/resep_mpasi_model.dart';

/// Service untuk mengelola data Resep MPASI di SQLite lokal.
///
/// Bertindak sebagai sumber data tunggal yang digunakan oleh:
/// - Halaman pengguna: DaftarResepPage, DetailResepPage
/// - Halaman PMIK/Superadmin: (untuk input & pengelolaan resep)
///
/// Data awal (seed) merupakan 7 resep default sesuai acuan desain.
/// PMIK/Superadmin dapat menambah, mengubah, dan menghapus resep melalui
/// service ini sehingga perubahan langsung terlihat di halaman pengguna.
class ResepMpasiService {
  static final ResepMpasiService _instance = ResepMpasiService._internal();
  factory ResepMpasiService() => _instance;
  ResepMpasiService._internal();

  static const String _dbName = 'pediagrow_resep.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'resep_mpasi';

  Database? _db;

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

    // Seed data awal dari PMIK/Superadmin (7 resep default sesuai desain)
    await _seedDefaultRecipes(db);
  }

  /// Seed 7 resep default. Data ini merepresentasikan resep yang sudah
  /// diinput oleh PMIK/Superadmin ke dalam sistem.
  Future<void> _seedDefaultRecipes(Database db) async {
    final recipes = [
      {
        'judul': 'Bubur Singkong Isi Ikan dan Ayam dengan Saus Jeruk',
        'kategori_usia': '6-8 bulan',
        'tanggal': '26 Agustus 2026',
        'asset_image_path': 'assets/images/resep_1.png',
        'penulis': 'Pego',
        'energi_kkal': 191.0,
        'lemak_gr': 9.0,
        'protein_gr': 10.5,
        'porsi': 3,
        'bahan':
            '200 gr tempe di potong kotak kecil, kukus\n100 gr daging ayam cincang, haluskan\n100 gr (2 butir) telur ayam, kocok\n50 gr (5 sdm) wortel\n50 gr (5 sdm) keju parut\n10 gr (1 batang) bawang daun, iris halus\n10 gr (1 sdm) bawang goreng halus\n10 gr (1 sdm) bawang putih halus\n20 gr (2 sdm) tepung terigu\n20 gr (2 sdm) tepung tapioka',
        'bahan_pelapis':
            '30 gr (3 sdm) tepung terigu\n100 ml air atau secukupnya\n100 gr (10 sdm) tepung panir\nMinyak untuk menggoreng secukupnya',
        'buah': '270 gr buah semangka',
        'cara_membuat':
            'Campurkan tempe, daging ayam cincang, wortel, keju, bawang daun, tepung terigu, tapioka, telur, bawang goreng, dan bawang putih halus. Aduk sampai tercampur rata. Ambil loyang olesi minyak dulu kemudian masukkan adonan nugget dan ratakan. Kukus selama 30 menit atau sampai matang. Setelah dingin potong adonan sesuai ukuran yang diinginkan.\nCairkan terigu dengan air sampai menjadi larutan yang cukup kekentalannya. Celupkan nugget ke tepung terigu basah, gulirkan pada tepung panir.\nSebaiknya disimpan dulu di kulkas selama 30 menit Atau bisa langsung di goreng di minyak yang panas. Sajikan selagi hangat. Bisa juga di jadikan lauk',
        'image_url': null,
      },
      {
        'judul': 'Bubur Soto Ayam Santan',
        'kategori_usia': '6-8 bulan',
        'tanggal': '26 Agustus 2026',
        'asset_image_path': 'assets/images/resep_2.png',
        'penulis': 'Pego',
        'energi_kkal': 175.0,
        'lemak_gr': 7.5,
        'protein_gr': 9.0,
        'porsi': 2,
        'bahan': '',
        'bahan_pelapis': '',
        'buah': '',
        'cara_membuat': '',
        'image_url': null,
      },
      {
        'judul': 'Puding Kentang Ayam dan Telur',
        'kategori_usia': '6-8 bulan',
        'tanggal': '26 Agustus 2026',
        'asset_image_path': 'assets/images/resep_3.png',
        'penulis': 'Pego',
        'energi_kkal': 160.0,
        'lemak_gr': 6.0,
        'protein_gr': 8.5,
        'porsi': 3,
        'bahan': '',
        'bahan_pelapis': '',
        'buah': '',
        'cara_membuat': '',
        'image_url': null,
      },
      {
        'judul': 'Nasi Tim Ikan Tuna Telur Puyuh',
        'kategori_usia': '9-11 bulan',
        'tanggal': '26 Agustus 2026',
        'asset_image_path': 'assets/images/resep_4.png',
        'penulis': 'Pego',
        'energi_kkal': 200.0,
        'lemak_gr': 8.0,
        'protein_gr': 12.0,
        'porsi': 2,
        'bahan': '',
        'bahan_pelapis': '',
        'buah': '',
        'cara_membuat': '',
        'image_url': null,
      },
      {
        'judul': 'Mie Kukus Telur Puyuh',
        'kategori_usia': '9-11 bulan',
        'tanggal': '26 Agustus 2026',
        'asset_image_path': 'assets/images/resep_5.png',
        'penulis': 'Pego',
        'energi_kkal': 185.0,
        'lemak_gr': 7.0,
        'protein_gr': 10.0,
        'porsi': 2,
        'bahan': '',
        'bahan_pelapis': '',
        'buah': '',
        'cara_membuat': '',
        'image_url': null,
      },
      {
        'judul': 'Tim Bubur Manado Daging dan Udang',
        'kategori_usia': '9-11 bulan',
        'tanggal': '26 Agustus 2026',
        'asset_image_path': 'assets/images/resep_6.png',
        'penulis': 'Pego',
        'energi_kkal': 210.0,
        'lemak_gr': 9.5,
        'protein_gr': 13.0,
        'porsi': 3,
        'bahan': '',
        'bahan_pelapis': '',
        'buah': '',
        'cara_membuat': '',
        'image_url': null,
      },
      {
        'judul': 'Nasi Soto Ayam Kuah Kuning',
        'kategori_usia': '12-23 bulan',
        'tanggal': '26 Agustus 2026',
        'asset_image_path': 'assets/images/resep_7.png',
        'penulis': 'Pego',
        'energi_kkal': 230.0,
        'lemak_gr': 10.0,
        'protein_gr': 14.0,
        'porsi': 3,
        'bahan': '',
        'bahan_pelapis': '',
        'buah': '',
        'cara_membuat': '',
        'image_url': null,
      },
    ];

    for (final recipe in recipes) {
      await db.insert(_tableName, recipe);
    }
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API (digunakan oleh pengguna maupun PMIK/Superadmin)
  // ---------------------------------------------------------------------------

  /// Ambil semua resep. Opsional filter by kategoriUsia dan/atau kata kunci.
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
      orderBy: 'id DESC',
    );

    return maps.map((m) => ResepMpasiModel.fromMap(m)).toList();
  }

  /// Ambil satu resep berdasarkan id.
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
    return db.insert(
      _tableName,
      resep.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update resep yang sudah ada (digunakan oleh PMIK/Superadmin).
  Future<int> updateResep(ResepMpasiModel resep) async {
    final db = await _database;
    return db.update(
      _tableName,
      resep.toMap(),
      where: 'id = ?',
      whereArgs: [resep.id],
    );
  }

  /// Hapus resep (digunakan oleh PMIK/Superadmin).
  Future<int> deleteResep(int id) async {
    final db = await _database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Tutup koneksi database.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
