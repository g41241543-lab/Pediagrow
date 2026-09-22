import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/artikel_model.dart';

/// Service untuk mengelola data Artikel Kesehatan di Cloud Firestore
/// (collection `artikel_kesehatan`).
///
/// Dipakai oleh:
/// - Sisi Pengguna/Dokter: `ArtikelKesehatanPage`, `DetailArtikelPage` (baca saja)
/// - Sisi PMIK/Superadmin: tambah, edit, dan hapus artikel
///
/// Cara kerja:
/// 1. Satu listener `snapshots()` ke Firestore menyimpan hasilnya di memori.
///    Pencarian dilakukan di memori, jadi mengetik di kolom cari tidak menambah
///    jumlah baca Firestore.
/// 2. Perubahan dari perangkat lain langsung masuk lewat listener dan tercermin
///    di [articlesNotifier].
/// 3. Jika collection masih kosong, 3 artikel default di
///    [ArtikelModel.seedArticles] diisikan otomatis.
class ArtikelService {
  static final ArtikelService _instance = ArtikelService._internal();
  factory ArtikelService() => _instance;
  ArtikelService._internal();

  static const String _collectionName = 'artikel_kesehatan';

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(_collectionName);

  final ValueNotifier<List<ArtikelModel>> _articlesNotifier =
      ValueNotifier<List<ArtikelModel>>([]);

  /// Notifier untuk mendengarkan perubahan daftar artikel secara real-time.
  ValueListenable<List<ArtikelModel>> get articlesNotifier => _articlesNotifier;

  /// Daftar artikel saat ini di memori (unmodifiable).
  List<ArtikelModel> get currentArticles =>
      List<ArtikelModel>.unmodifiable(_articlesNotifier.value);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Completer<void>? _ready;

  // ---------------------------------------------------------------------------
  // LISTENER & SEED
  // ---------------------------------------------------------------------------

  /// Memastikan listener aktif dan data pertama sudah diterima.
  Future<void> _ensureListening() {
    final existing = _ready;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _ready = completer;

    () async {
      await _seedIfEmpty();

      _subscription = _col.snapshots().listen(
        (snap) {
          // Dokumen yang timestamp-nya belum terisi dianggap paling baru.
          final now = DateTime.now();
          final docs = snap.docs.toList()
            ..sort((a, b) {
              final ta =
                  (a.data()['createdAt'] as Timestamp?)?.toDate() ?? now;
              final tb =
                  (b.data()['createdAt'] as Timestamp?)?.toDate() ?? now;
              return ta.compareTo(tb);
            });
          _articlesNotifier.value =
              docs.map(ArtikelModel.fromFirestore).toList();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object e) {
          debugPrint('Listener artikel_kesehatan error: $e');
          if (!completer.isCompleted) completer.completeError(e);
          // Reset supaya pemanggilan berikutnya mencoba ulang.
          _subscription?.cancel();
          _subscription = null;
          _ready = null;
        },
      );
    }();

    return completer.future;
  }

  /// Isi artikel default jika collection masih kosong.
  /// ID dokumen dibuat tetap (artikel_1 ... artikel_3) sehingga aman jika
  /// dijalankan dua perangkat bersamaan (tidak menghasilkan duplikat).
  Future<void> _seedIfEmpty() async {
    try {
      final check = await _col.limit(1).get();
      if (check.docs.isNotEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      _addSeedToBatch(batch);
      await batch.commit();
    } catch (e) {
      // Jangan menggagalkan pemuatan daftar hanya karena seed gagal.
      debugPrint('Seed artikel_kesehatan dilewati: $e');
    }
  }

  void _addSeedToBatch(WriteBatch batch) {
    // createdAt dibuat berurutan agar urutan artikel 1..3 tetap terjaga.
    final base = DateTime(2026, 8, 26);
    var i = 0;
    for (final artikel in ArtikelModel.seedArticles) {
      final stamp = Timestamp.fromDate(base.add(Duration(minutes: i++)));
      batch.set(_col.doc(artikel.id), {
        ...artikel.toFirestore(),
        'createdAt': stamp,
        'updatedAt': stamp,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  /// Memuat seluruh artikel (opsional difilter judul).
  /// Tanda tangan fungsi sama dengan versi SQLite sebelumnya.
  Future<List<ArtikelModel>> getAllArticles({String? searchQuery}) async {
    await _ensureListening();
    final query = searchQuery?.trim() ?? '';
    if (query.isEmpty) return List<ArtikelModel>.of(_articlesNotifier.value);
    return filterArticles(query);
  }

  /// Mengambil satu artikel berdasarkan ID dokumen.
  Future<ArtikelModel?> getArticleById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? ArtikelModel.fromFirestore(doc) : null;
  }

  /// Filter lokal cepat untuk live searching judul.
  List<ArtikelModel> filterArticles(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return currentArticles;
    return currentArticles
        .where((art) => art.judul.toLowerCase().contains(cleanQuery))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // MANAJEMEN DATA OLEH PMIK (ADMIN & SUPERADMIN)
  // ---------------------------------------------------------------------------

  /// Tambah artikel baru. Mengembalikan ID dokumen.
  Future<String> tambahArtikel(ArtikelModel artikel) async {
    final Map<String, dynamic> data = {
      ...artikel.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (artikel.id != null && artikel.id!.isNotEmpty) {
      await _col.doc(artikel.id).set(data);
      return artikel.id!;
    }
    final ref = await _col.add(data);
    return ref.id;
  }

  /// Perbarui artikel yang ada. Mengembalikan 1 jika berhasil,
  /// 0 jika artikel tidak punya ID.
  Future<int> updateArtikel(ArtikelModel artikel) async {
    final id = artikel.id;
    if (id == null || id.isEmpty) return 0;
    await _col.doc(id).update({
      ...artikel.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return 1;
  }

  /// Hapus artikel. Mengembalikan 1 jika berhasil.
  Future<int> hapusArtikel(String id) async {
    await _col.doc(id).delete();
    return 1;
  }

  /// Kosongkan seluruh artikel (untuk menguji tampilan kosong).
  /// Hati-hati: ini menghapus data di Firestore untuk semua pengguna.
  Future<void> clearAllArticles() async {
    final existing = await _col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Hapus semua artikel lalu isi ulang dengan 3 artikel default.
  Future<void> resetToDefault() async {
    final existing = await _col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    _addSeedToBatch(batch);
    await batch.commit();
  }

  /// Hentikan listener (misalnya saat logout).
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _ready = null;
  }
}
