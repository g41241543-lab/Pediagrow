import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/resep_mpasi_model.dart';

/// Service untuk mengelola data Resep MPASI di Cloud Firestore
/// (collection `resep_mpasi`).
///
/// Dipakai oleh:
/// - Halaman Pengguna/Dokter: [DaftarResepPage], [DetailResepPage] (baca saja)
/// - Halaman PMIK/Superadmin: input, edit, dan hapus resep
///
/// Cara kerja:
/// 1. Service memasang satu listener `snapshots()` ke Firestore dan menyimpan
///    hasilnya di memori. Pencarian dan filter usia dilakukan di memori,
///    jadi mengetik di kolom cari tidak menambah jumlah baca Firestore.
/// 2. Perubahan dari perangkat lain (PMIK menambah/mengubah resep) langsung
///    masuk lewat listener dan tercermin di [recipesNotifier].
/// 3. Jika collection masih kosong, 7 resep default Kemenkes di
///    [ResepMpasiModel.defaultKemenkesRecipes] diisikan otomatis.
class ResepMpasiService {
  static final ResepMpasiService _instance = ResepMpasiService._internal();
  factory ResepMpasiService() => _instance;
  ResepMpasiService._internal();

  static const String _collectionName = 'resep_mpasi';

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(_collectionName);

  /// Notifier reaktif untuk mendengarkan perubahan daftar resep.
  final ValueNotifier<List<ResepMpasiModel>> _recipesNotifier =
      ValueNotifier<List<ResepMpasiModel>>([]);
  ValueListenable<List<ResepMpasiModel>> get recipesNotifier =>
      _recipesNotifier;

  /// Daftar resep terkini di memori.
  List<ResepMpasiModel> get currentRecipes =>
      List<ResepMpasiModel>.unmodifiable(_recipesNotifier.value);

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
          _recipesNotifier.value =
              docs.map(ResepMpasiModel.fromFirestore).toList();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object e) {
          debugPrint('Listener resep_mpasi error: $e');
          if (!completer.isCompleted) completer.completeError(e);
          // Reset supaya pemanggilan berikutnya (tombol "Coba Lagi") mencoba ulang.
          _subscription?.cancel();
          _subscription = null;
          _ready = null;
        },
      );
    }();

    return completer.future;
  }

  /// Isi 7 resep default jika collection masih kosong.
  /// ID dokumen dibuat tetap (resep_1 ... resep_7) sehingga aman jika
  /// dijalankan dua perangkat bersamaan (tidak menghasilkan duplikat).
  Future<void> _seedIfEmpty() async {
    try {
      final check = await _col.limit(1).get();
      if (check.docs.isNotEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      _addSeedToBatch(batch);
      await batch.commit();
    } catch (e) {
      // Jangan menggagalkan pemuatan daftar hanya karena seed gagal
      // (misalnya pengguna tidak punya izin tulis).
      debugPrint('Seed resep_mpasi dilewati: $e');
    }
  }

  void _addSeedToBatch(WriteBatch batch) {
    // createdAt dibuat berurutan agar urutan resep 1..7 tetap terjaga.
    final base = DateTime(2026, 8, 26);
    var i = 0;
    for (final recipe in ResepMpasiModel.defaultKemenkesRecipes) {
      final stamp = Timestamp.fromDate(base.add(Duration(minutes: i++)));
      batch.set(_col.doc(recipe.id), {
        ...recipe.toFirestore(),
        'createdAt': stamp,
        'updatedAt': stamp,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API (dipakai pengguna maupun PMIK/Superadmin)
  // ---------------------------------------------------------------------------

  /// Ambil semua resep dengan filter kategoriUsia dan/atau kata kunci judul.
  /// Tanda tangan fungsi sama dengan versi SQLite sebelumnya.
  Future<List<ResepMpasiModel>> getAllResep({
    String? kategoriUsia,
    String? searchQuery,
  }) async {
    await _ensureListening();

    final query = searchQuery?.trim().toLowerCase() ?? '';
    final filterUsia = kategoriUsia != null && kategoriUsia != 'Semua';

    return _recipesNotifier.value.where((r) {
      if (filterUsia && r.kategoriUsia != kategoriUsia) return false;
      if (query.isNotEmpty && !r.judul.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Ambil satu resep berdasarkan ID dokumen.
  Future<ResepMpasiModel?> getResepById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? ResepMpasiModel.fromFirestore(doc) : null;
  }

  /// Tambah resep baru (PMIK/Superadmin). Mengembalikan ID dokumen.
  Future<String> insertResep(ResepMpasiModel resep) async {
    final Map<String, dynamic> data = {
      ...resep.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (resep.id != null && resep.id!.isNotEmpty) {
      await _col.doc(resep.id).set(data);
      return resep.id!;
    }
    final ref = await _col.add(data);
    return ref.id;
  }

  /// Ubah resep yang sudah ada (PMIK/Superadmin). Mengembalikan 1 jika berhasil,
  /// 0 jika resep tidak punya ID.
  Future<int> updateResep(ResepMpasiModel resep) async {
    final id = resep.id;
    if (id == null || id.isEmpty) return 0;
    await _col.doc(id).update({
      ...resep.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return 1;
  }

  /// Hapus resep (PMIK/Superadmin). Mengembalikan 1 jika berhasil.
  Future<int> deleteResep(String id) async {
    await _col.doc(id).delete();
    return 1;
  }

  /// Hapus semua resep lalu isi ulang dengan 7 resep default Kemenkes.
  Future<void> resetToDefault() async {
    final existing = await _col.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    _addSeedToBatch(batch);
    await batch.commit();
  }

  /// Hentikan listener (dipanggil jika perlu, misalnya saat logout).
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _ready = null;
  }
}
