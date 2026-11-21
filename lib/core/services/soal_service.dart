import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/soal_model.dart';
import '../../models/staff_account_model.dart';
import 'api_service.dart';
import 'staff_auth_service.dart';

/// Service untuk mengelola Bank Soal Kuis Parenting (25 Soal & CRUD).
///
/// Menyediakan sinkronisasi Cloud Firestore (`bank_soal`),
/// In-Memory Cache, SharedPreferences offline storage, dan API fallback.
class SoalService {
  static const Duration _timeout = Duration(milliseconds: 2500);
  static const String _collectionName = 'bank_soal';
  static const String _prefCacheKey = 'bank_soal_local_cache';
  static const String _prefSeededKey = 'bank_soal_seeded_v25';

  /// In-memory cache bank soal
  static List<SoalModel>? _cache;

  /// Mengambil data soal dari cache jika tersedia
  static List<SoalModel>? get cachedSoal =>
      _cache != null ? List.unmodifiable(_cache!) : null;

  static CollectionReference<Map<String, dynamic>>? get _firestoreCol {
    try {
      return FirebaseFirestore.instance.collection(_collectionName);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // HAK AKSES & OTORISASI (ROLE ADMIN & SUPERADMIN ONLY)
  // ──────────────────────────────────────────────────────────────────

  /// Memverifikasi bahwa pengakses memiliki hak akses Admin (PMIK) atau Superadmin.
  /// Menolak role Dokter, User, atau sesi tanpa login.
  static void _checkStaffWritePermission() {
    final staff = StaffAuthService().currentStaff;
    if (staff == null) {
      throw StateError(
        '403 Forbidden: Akses ditolak. Anda harus login sebagai Admin atau Superadmin.',
      );
    }
    if (staff.role != StaffRole.admin && staff.role != StaffRole.superadmin) {
      throw StateError(
        '403 Forbidden: Role ${staff.role.label} tidak memiliki izin mengelola Bank Soal.',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // LOAD INITIAL & PERSISTENCE
  // ──────────────────────────────────────────────────────────────────

  /// Mengambil data awal secepat mungkin (0 - 25 ms):
  /// 1. Dari memory cache jika ada
  /// 2. Dari SharedPreferences jika ada
  /// 3. Dari file JSON asset lokal
  static Future<List<SoalModel>> loadInitialSoal() async {
    if (_cache != null && _cache!.isNotEmpty) {
      return List<SoalModel>.from(_cache!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson) as List<dynamic>;
        final list = decoded
            .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _cache = List<SoalModel>.from(list);
          return list;
        }
      }
    } catch (_) {}

    final assetData = await _loadFromAsset();
    if (assetData.isNotEmpty) {
      _cache = List<SoalModel>.from(assetData);
      _saveToLocalPrefs(assetData);
    }
    return assetData;
  }

  /// Menyimpan daftar bank soal ke SharedPreferences lokal
  static Future<void> _saveToLocalPrefs(List<SoalModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_prefCacheKey, encoded);
    } catch (_) {}
  }

  /// Membaca bank soal dari file asset JSON (25 soal resmi)
  static Future<List<SoalModel>> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/data/soal_kuis.json');
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SoalService._loadFromAsset error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // GET ALL & GET AKTIF
  // ──────────────────────────────────────────────────────────────────

  /// Mengambil seluruh bank soal (aktif maupun nonaktif) dari database.
  static Future<List<SoalModel>> getAllSoal({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null && _cache!.isNotEmpty) {
      return List<SoalModel>.from(_cache!);
    }

    // 1. Coba ambil dari Firestore
    final col = _firestoreCol;
    if (col != null) {
      try {
        await _seedIfEmpty(col);
        final snap = await col.orderBy('id').get().timeout(_timeout);
        if (snap.docs.isNotEmpty) {
          final serverList = snap.docs
              .map((d) => SoalModel.fromJson(d.data()))
              .toList();
          _cache = List<SoalModel>.from(serverList);
          await _saveToLocalPrefs(serverList);
          return serverList;
        }
      } catch (e) {
        debugPrint('SoalService.getAllSoal Firestore error/timeout: $e');
      }
    }

    // 2. Coba API HTTP Backend jika ada
    try {
      final root = await ApiService.getEffectiveBaseUrl();
      final response = await http
          .get(
            Uri.parse('$root/permainan/get_soal.php'),
            headers: {'Accept': 'application/json; charset=utf-8'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List && decoded.isNotEmpty) {
          final apiList = decoded
              .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _cache = List<SoalModel>.from(apiList);
          await _saveToLocalPrefs(apiList);
          return apiList;
        }
      }
    } catch (_) {}

    // 3. Fallback memory atau SharedPreferences atau Asset
    return loadInitialSoal();
  }

  /// Mengambil soal-soal yang berstatus aktif saja (untuk Kuis User)
  static Future<List<SoalModel>> getSoalAktif() async {
    final all = await getAllSoal();
    return all.where((s) => s.isActive).toList();
  }

  /// Sinkronisasi data di latar belakang
  static Future<List<SoalModel>?> syncInBackground() async {
    try {
      return await getAllSoal(forceRefresh: true);
    } catch (_) {
      return null;
    }
  }

  /// Seed otomatis 25 soal jika koleksi Firestore masih kosong
  static Future<void> _seedIfEmpty(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefSeededKey) == true) return;

      final existing = await col.limit(1).get().timeout(_timeout);
      if (existing.docs.isNotEmpty) {
        await prefs.setBool(_prefSeededKey, true);
        return;
      }

      final seedList = await _loadFromAsset();
      final batch = FirebaseFirestore.instance.batch();
      for (final s in seedList) {
        final docRef = col.doc('soal_${s.id}');
        batch.set(docRef, {
          ...s.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      await prefs.setBool(_prefSeededKey, true);
    } catch (e) {
      debugPrint('SoalService._seedIfEmpty error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // CRUD OPERATIONS (CREATE, UPDATE, DELETE)
  // ──────────────────────────────────────────────────────────────────

  /// Menambah soal baru ke bank soal.
  ///
  /// Validasi:
  /// - Hak akses role Admin/Superadmin
  /// - Pertanyaan & penjelasan tidak boleh kosong/spasi
  /// - Mencegah duplikasi teks pertanyaan
  static Future<({bool success, String? message, SoalModel? soal})> tambahSoal({
    required String kategori,
    required String pertanyaan,
    required bool jawabanBenar,
    required String penjelasan,
  }) async {
    try {
      _checkStaffWritePermission();
    } catch (e) {
      return (success: false, message: e.toString(), soal: null);
    }

    final pClean = pertanyaan.trim();
    final jClean = penjelasan.trim();
    final kClean = kategori.trim().isEmpty ? 'Umum' : kategori.trim();

    if (pClean.isEmpty) {
      return (success: false, message: 'Pertanyaan soal tidak boleh kosong.', soal: null);
    }
    if (jClean.isEmpty) {
      return (success: false, message: 'Penjelasan soal tidak boleh kosong.', soal: null);
    }

    final currentList = await getAllSoal();

    // Validasi duplikasi pertanyaan
    final isDuplicate = currentList.any(
      (s) => s.pertanyaan.trim().toLowerCase() == pClean.toLowerCase(),
    );
    if (isDuplicate) {
      return (
        success: false,
        message: 'Pertanyaan tersebut sudah terdaftar dalam bank soal (duplikat).',
        soal: null,
      );
    }

    // Tentukan ID baru (max(id) + 1)
    int nextId = 1;
    if (currentList.isNotEmpty) {
      final maxId = currentList.map((e) => e.id).reduce((a, b) => a > b ? a : b);
      nextId = maxId + 1;
    }

    final now = DateTime.now();
    final newSoal = SoalModel(
      id: nextId,
      kategori: kClean,
      pertanyaan: pClean,
      jawabanBenar: jawabanBenar,
      penjelasan: jClean,
      isActive: true,
      perluTinjauan: false,
      createdAt: now,
      updatedAt: now,
    );

    // Simpan ke Firestore
    final col = _firestoreCol;
    if (col != null) {
      try {
        await col.doc('soal_$nextId').set({
          ...newSoal.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }).timeout(_timeout);
      } catch (e) {
        debugPrint('Firestore tambahSoal error: $e');
      }
    }

    // Simpan ke API HTTP jika ada
    try {
      final root = await ApiService.getEffectiveBaseUrl();
      await http
          .post(
            Uri.parse('$root/permainan/tambah_soal.php'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(newSoal.toJson()),
          )
          .timeout(_timeout);
    } catch (_) {}

    // Perbarui cache memori dan lokal
    currentList.add(newSoal);
    _cache = List<SoalModel>.from(currentList);
    await _saveToLocalPrefs(currentList);

    return (success: true, message: 'Soal berhasil ditambahkan ke Bank Soal.', soal: newSoal);
  }

  /// Memperbarui soal yang sudah ada.
  static Future<({bool success, String? message, SoalModel? soal})> updateSoal({
    required int id,
    required String pertanyaan,
    required bool jawabanBenar,
    required String penjelasan,
    String? kategori,
    bool? isActive,
    bool? perluTinjauan,
  }) async {
    try {
      _checkStaffWritePermission();
    } catch (e) {
      return (success: false, message: e.toString(), soal: null);
    }

    final pClean = pertanyaan.trim();
    final jClean = penjelasan.trim();

    if (pClean.isEmpty) {
      return (success: false, message: 'Pertanyaan soal tidak boleh kosong.', soal: null);
    }
    if (jClean.isEmpty) {
      return (success: false, message: 'Penjelasan soal tidak boleh kosong.', soal: null);
    }

    final currentList = await getAllSoal();
    final idx = currentList.indexWhere((s) => s.id == id);
    if (idx == -1) {
      return (success: false, message: 'Soal tidak ditemukan.', soal: null);
    }

    // Validasi duplikasi dengan soal lain
    final isDuplicate = currentList.any(
      (s) => s.id != id && s.pertanyaan.trim().toLowerCase() == pClean.toLowerCase(),
    );
    if (isDuplicate) {
      return (
        success: false,
        message: 'Pertanyaan tersebut sudah terdaftar pada soal lain (duplikat).',
        soal: null,
      );
    }

    final oldSoal = currentList[idx];
    final now = DateTime.now();
    final updatedSoal = oldSoal.copyWith(
      pertanyaan: pClean,
      jawabanBenar: jawabanBenar,
      penjelasan: jClean,
      kategori: kategori?.trim().isNotEmpty == true ? kategori!.trim() : oldSoal.kategori,
      isActive: isActive ?? oldSoal.isActive,
      perluTinjauan: perluTinjauan ?? oldSoal.perluTinjauan,
      updatedAt: now,
    );

    // Update Firestore
    final col = _firestoreCol;
    if (col != null) {
      try {
        await col.doc('soal_$id').set({
          ...updatedSoal.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(_timeout);
      } catch (e) {
        debugPrint('Firestore updateSoal error: $e');
      }
    }

    // Update API HTTP
    try {
      final root = await ApiService.getEffectiveBaseUrl();
      await http
          .post(
            Uri.parse('$root/permainan/update_soal.php'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(updatedSoal.toJson()),
          )
          .timeout(_timeout);
    } catch (_) {}

    currentList[idx] = updatedSoal;
    _cache = List<SoalModel>.from(currentList);
    await _saveToLocalPrefs(currentList);

    return (success: true, message: 'Soal berhasil diperbarui.', soal: updatedSoal);
  }

  /// Menghapus soal dari bank soal.
  ///
  /// Syarat:
  /// - Hak akses role Admin/Superadmin
  /// - Bank soal TIDAK boleh kurang dari 10 soal (karena 1 sesi butuh 10 soal).
  static Future<({bool success, String message})> hapusSoal(int id) async {
    try {
      _checkStaffWritePermission();
    } catch (e) {
      return (success: false, message: e.toString());
    }

    final currentList = await getAllSoal();
    if (currentList.length <= 10) {
      return (
        success: false,
        message: 'Bank soal tidak dapat dikurangi lagi (minimal 10 soal untuk 1 sesi kuis).',
      );
    }

    final idx = currentList.indexWhere((s) => s.id == id);
    if (idx == -1) {
      return (success: false, message: 'Soal tidak ditemukan.');
    }

    // Hapus dari Firestore
    final col = _firestoreCol;
    if (col != null) {
      try {
        await col.doc('soal_$id').delete().timeout(_timeout);
      } catch (e) {
        debugPrint('Firestore hapusSoal error: $e');
      }
    }

    // Hapus dari API HTTP
    try {
      final root = await ApiService.getEffectiveBaseUrl();
      await http
          .post(
            Uri.parse('$root/permainan/hapus_soal.php'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'id': id}),
          )
          .timeout(_timeout);
    } catch (_) {}

    currentList.removeAt(idx);
    _cache = List<SoalModel>.from(currentList);
    await _saveToLocalPrefs(currentList);

    return (success: true, message: 'Soal berhasil dihapus dari Bank Soal.');
  }

  /// Memperbarui cache lokal langsung
  static void updateCache(SoalModel updated) {
    if (_cache == null) {
      _cache = [updated];
      return;
    }
    final index = _cache!.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _cache![index] = updated;
    } else {
      _cache!.add(updated);
    }
    _saveToLocalPrefs(_cache!);
  }

  /// Mengosongkan cache
  static void clearCache() {
    _cache = null;
  }
}
